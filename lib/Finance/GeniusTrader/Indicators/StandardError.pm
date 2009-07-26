package Finance::GeniusTrader::Indicators::StandardError;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# standards upgrade Copyright 2005 Thomas Weigert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# requires Thomas Weigert revision to Finance::GeniusTrader::Indicators::LinearRegression
# $Id$

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::LinearRegression;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("StandardError[#1, #2]");
@DEFAULT_ARGS = (20, "{I:Prices CLOSE}");

=pod

=head1 Finance::GeniusTrader::Indicators::StandardError

=head2 Overview

Standard Error is a statistical measure of volatility. Standard Error is
typically used as a component of other indicators, rather than as a
stand-alone indicator. For example, Kirshenbaum Bands are calculated by
adding a security's Standard Error to an exponential moving average.

=head2 Calculation

Calculate the L-Period linear regression line, using today's Close as the
endpoint of the line. Note : The term "linear regression" is the same as
"least squares" or "best fit" line in some textbooks.

Calculate d1, d2, d3, ..., dL as the distance from the line to the Close
of each bar which was used to derive the line. That is, d(i) = Distance
from Regression Line to each bar's Close.

Average of squared errors (AE) = (d1² + d2² + d3² + ... + dL²) / L
Standard Error = Square Root of AE

=cut

sub initialize {
    my $self = shift;

    # Linear regression of the CLOSE against the sequence number
    $self->{'linear_regression_line'} = Finance::GeniusTrader::Indicators::LinearRegression->new([ $self->{'args'}->get_arg_names(1), $self->{'args'}->get_arg_names(2) ]);

    $self->add_indicator_dependency($self->{'linear_regression_line'}, $self->{'args'}->get_arg_constant(1));
    $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_constant(1);
    my $linear_regression_coefficient_a_name = $self->{'linear_regression_line'}->get_name(1);
    my $linear_regression_coefficient_b_name = $self->{'linear_regression_line'}->get_name(2);
    my $standard_error_name = $self->get_name;
    my $sum_of_the_squared_errors = 0;

    return if ($indic->is_available($standard_error_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Calculate and get the linear regression line coefficients
    my $a = $indic->get($linear_regression_coefficient_a_name, $i);
    my $b = $indic->get($linear_regression_coefficient_b_name, $i);

    # Calculate the Standard Error
    for (my $n = $i - $period + 1; $n <= $i; $n++) {

	# Calculate the linear regression line value
	my $linear_regression_line_value = $a * $n + $b;
	
	# Calculate the distance from the linear regression line
	my $d = $self->{'args'}->get_arg_values($calc, $n, 2) - $linear_regression_line_value;

	# Calculate the sum of the squared errors
	$sum_of_the_squared_errors += ($d ** 2);
    }

    # Calculate the average of the squared errors
    my $average_of_the_squared_errors = $sum_of_the_squared_errors / $period;

    # Calculate the standard error
    my $standard_error = sqrt($average_of_the_squared_errors);

    # Return the results
    $indic->set($standard_error_name, $i, $standard_error);
}

1;
