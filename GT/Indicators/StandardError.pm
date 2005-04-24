package GT::Indicators::StandardError;

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Indicators::LinearRegression;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("StandardError[#1]");

=pod

=head1 GT::Indicators::StandardError

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

Average of squared errors (AE) = (d1� + d2� + d3� + ... + dL�) / L
Standard Error = Square Root of AE

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args, $key, $func) = @_;
    my $self = { 'args' => defined($args) ? $args : [ 20 ] };

    $args->[0] = 20 if (! defined($args->[0]));
    
    if (defined($func)) {
	$self->{'_func'} = $func;
    } else {
	$self->{'_func'} = $GET_LAST;
	$key = 'LAST';
    }
						
    return manage_object(\@NAMES, $self, $class, $args, $key);
}

sub initialize {
    my $self = shift;

    $self->{'linear_regression_line'} = GT::Indicators::LinearRegression->new([ $self->{'args'}[0] ], $self->{'key'}, sub { return $_[1] }, sub { $self->{'_func'}(@_) } );

    $self->add_indicator_dependency($self->{'linear_regression_line'}, $self->{'args'}[0]);
    $self->add_prices_dependency($self->{'args'}[0]);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}[0];
    my $getvalue = $self->{'_func'};
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
	my $d = &$getvalue($calc, $n) - $linear_regression_line_value;

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
