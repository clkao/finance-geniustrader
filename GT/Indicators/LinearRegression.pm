package GT::Indicators::LinearRegression;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# standards upgrade Copyright 2005 Thomas Weigert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id$

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("LinearRegressionLine[#1,#2,#3]","LinearRegressionCoefficientA[#1,#2,#3]","LinearRegressionCoefficientB[#1,#2,#3]");

=head1 GT::Indicators::LinearRegression

This function will calculate an L-Period linear regression line. Note that
the term "linear regression" is the same as a "least squares" or "best
fit" line.

The linear regression value is "a * i + b". i is the day number. a and b
are also provided by the indicator if you want to calculate the value of
the linear regression for other days.

=head2 Parameters

Takes 2 or 3 parameters. The first is the period over which the regression
is calculated. The following parameters indicate the series that are being
compared. If there is only a second parameter, this parameter forms the
dependent variables, while the numerical sequence is the independent
parameter. If there are both a second and a third parameter, the former is
the independent and the latter the dependent parameter.
    
=cut

sub initialize {
    my ($self) = @_;

    # No default value for the first arg on purpose
    # It means use all the values for the regression and not only the XX
    # latest
    if (defined $self->{'args'}[0]) {
        $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
    }
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $linear_regression_line_name = $self->get_name(0);
    my $linear_regression_coefficient_a_name = $self->get_name(1);
    my $linear_regression_coefficient_b_name = $self->get_name(2);
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my ($sum_x, $sum_y, $sum_xy) = 0;
    my ($variance_x, $variance_y) = 0;
    
    return if ($calc->indicators->is_available($linear_regression_line_name, $i) &&
               $calc->indicators->is_available($linear_regression_coefficient_a_name, $i) &&
	       $calc->indicators->is_available($linear_regression_coefficient_b_name, $i));

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $period);
    $self->add_volatile_arg_dependency(3, $period);

    return if (! $self->check_dependencies($calc, $i));

    # Initialize $period to $i if nothing was previously defined
    if (!defined $period) {
	$period = $i;
    }
    
    # Calculate the average of (x), (y) and (xy)
    for(my $n = $i - $period + 1; $n <= $i; $n++) {

        my $x = $self->{'args'}->get_arg_values($calc, $n, 2);
        my $y;
        if ( defined( $self->{'args'}->get_arg_object(3) ) ) {
          my $y = $self->{'args'}->get_arg_values($calc, $n, 3);
        } else {
          $y = $x;
          $x = $n;
        }

        $sum_x += $x;
        $sum_y += $y;
        $sum_xy += ($x * $y);
    }
    
    my $average_x = $sum_x / $period;
    my $average_y = $sum_y / $period;
    my $average_xy = $sum_xy / $period;

    # Calculate the variance of (x) and (y)
    for(my $n = $i - $period + 1; $n <= $i; $n++) {

        my $x = $self->{'args'}->get_arg_values($calc, $n, 2);
        my $y;
        if ( defined( $self->{'args'}->get_arg_object(3) ) ) {
          my $y = $self->{'args'}->get_arg_values($calc, $n, 3);
        } else {
          $y = $x;
          $x = $n;
        }

        $variance_x += (($x - $average_x) ** 2);
        $variance_y += (($y - $average_y) ** 2);
    }
    $variance_x /= $period;
    $variance_y /= $period;

    # Calculate the covariance(x,y)
    my $covariance = $average_xy - $average_x * $average_y;
    
    # Calculate the linear regression coefficients
    my $a = $covariance / $variance_x;
    my $b = $average_y - $a * $average_x;

    # Calculate the linear regression line value
    my $linear_regression_line_value = $a * $i + $b;
    
    # Return the results
    $calc->indicators->set($linear_regression_line_name, $i, $linear_regression_line_value);
    $calc->indicators->set($linear_regression_coefficient_a_name, $i, $a);
    $calc->indicators->set($linear_regression_coefficient_b_name, $i, $b);
}

1;
