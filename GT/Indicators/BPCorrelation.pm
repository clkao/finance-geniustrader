package GT::Indicators::BPCorrelation;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("BPCorrelation[#1]");

=head2 GT::Indicators::Correlation

This function will calculate the Bravais-Pearson Correlation Coefficient.
Correlation analysis measures the relationship between two items and shows
if changes in one item will result in changes in the other item.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args, $key, $f1, $f2) = @_;
    my $self = { 'args' => defined($args) ? $args : [] };

    if (defined($f1)) {
	$self->{'_f1'} = $f1;
    }
    if (defined($f2)) {
        $self->{'_f2'} = $f2;
    }

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, $key);
}

sub initialize {
    my ($self) = @_;

    $self->add_prices_dependency(20);
}

=head2 GT::Indicators::Correlation::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $getvalue1 = $self->{'_f1'};
    my $getvalue2 = $self->{'_f2'};
    my $name = $self->get_name;
    my $period = $self->{'args'}[0];
    my $average_x = 0;
    my $average_y = 0;
    my $sum_y = 0;
    my $sum_x = 0;
    my $sum_xy = 0;
    
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
    return if (defined($period) && ($i + 1 < $period));

    if (!defined $period) {
	$period = $i;
    }
    
    for(my $n = $i - $period + 1; $n <= $i; $n++) {

	$average_x += &$getvalue1($calc, $n);
	$average_y += &$getvalue2($calc, $n);
    }
    
    $average_x /= $period;
    $average_y /= $period;
    
    for(my $n = $i - $period + 1; $n <= $i; $n++) {
	$sum_x += (&$getvalue1($calc, $n) - $average_x) ** 2;
	$sum_y += (&$getvalue2($calc, $n) - $average_y) ** 2;
	$sum_xy += (&$getvalue1($calc, $n) - $average_x) *
		   (&$getvalue2($calc, $n) - $average_y);
    }

    # Calculate the Bravais-Pearson Correlation Coefficient
    my $correlation = $sum_xy / ( ($sum_x * $sum_y) ** (1/2) );
    
    # Return the result
    $calc->indicators->set($name, $i, $correlation);
}

1;
