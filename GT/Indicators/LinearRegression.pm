package GT::Indicators::LinearRegression;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("LinearRegressionLine[#1]","LinearRegressionCoefficientA[#1]","LinearRegressionCoefficientB[#1]");

=head1 GT::Indicators::LinearRegression

This function will calculate an L-Period linear regression line. Note that
the term "linear regression" is the same as a "least squares" or "best
fit" line.

The linear regression value is "a * i + b". i is the day number. a and b
are also provided by the indicator if you want to calculate the value of
the linear regression for other days.

=head2 GT::Indicators::LinearRegression->new([$length], $key, $func1, $func2)

Create a new LinearRegression indicator. Please note that the key must
be unique for the combination of both data series ($func1 and $func2)
so that the generated name of the indicator is unique. It is highly
recommended to use a key such as "serie1_name,serie2_name".
    
=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args, $key, $f1, $f2) = @_;
    # No default value for the first arg on purpose
    # It means use all the values for the regression and not only the XX
    # latest
    my $self = { 'args' => defined($args) ? $args : [] };

    if (defined($f1)) {
	$self->{'_f1'} = $f1;
    } else { die "Missing data serie.\n"; }
    if (defined($f2)) {
        $self->{'_f2'} = $f2;
    } else { die "Missing data serie.\n"; }

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, $key);
}

sub initialize {
    my ($self) = @_;

    if (defined $self->{'args'}[0]) {
	$self->add_prices_dependency($self->{'args'}[0]);
    }
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $getvalue1 = $self->{'_f1'};
    my $getvalue2 = $self->{'_f2'};
    my $linear_regression_line_name = $self->get_name(0);
    my $linear_regression_coefficient_a_name = $self->get_name(1);
    my $linear_regression_coefficient_b_name = $self->get_name(2);
    my $period = $self->{'args'}[0];
    my ($sum_x, $sum_y, $sum_xy) = 0;
    my ($variance_x, $variance_y) = 0;
    
    return if ($calc->indicators->is_available($linear_regression_line_name, $i) &&
               $calc->indicators->is_available($linear_regression_coefficient_a_name, $i) &&
	       $calc->indicators->is_available($linear_regression_coefficient_b_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Initialize $period to $i if nothing was previously defined
    if (!defined $period) {
	$period = $i;
    }
    
    # Calculate the average of (x), (y) and (xy)
    for(my $n = $i - $period + 1; $n <= $i; $n++) {

	$sum_x += &$getvalue1($calc, $n);
	$sum_y += &$getvalue2($calc, $n);
	$sum_xy += (&$getvalue1($calc, $n) * &$getvalue2($calc, $n));
    }
    
    my $average_x = $sum_x / $period;
    my $average_y = $sum_y / $period;
    my $average_xy = $sum_xy / $period;

    # Calculate the variance of (x) and (y)
    for(my $n = $i - $period + 1; $n <= $i; $n++) {

	$variance_x += ((&$getvalue1($calc, $n) - $average_x) ** 2);
	$variance_y += ((&$getvalue2($calc, $n) - $average_y) ** 2);
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
