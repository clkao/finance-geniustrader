package GT::Indicators::RSI;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("RSI[#*]");
@DEFAULT_ARGS = (14, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::RSI - Relative Strength Index

=head1 DESCRIPTION

The standard RSI is the RSI 14 days : GT::Indicators::RSI->new()
If you need a non standard RSI use for example : GT::Indicators::RSI->new([25])

=head2 Validation

This indicators is validated by the values from comdirect.de.
The stock used was the DAX (data from yahoo) at the 04.06.2003:

RSI[14,{I:Prices CLOSE}][2003-06-04] = 57.5433 (comdirect=57.54)

=cut
sub initialize {
    my ($self) = @_;

    if ($self->{'args'}->is_constant(1)) {
	$self->add_prices_dependency($self->{'args'}->get_arg_constant(1) + 1);
    } else {
	#no harcoded dependency
    }
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $sum_of_won_points = 0;
    my $sum_of_lost_points = 0;
    my $rs = 0;
    my $rsi = 0;

    if (! $self->{'args'}->is_constant(1)) {
	$self->remove_volatile_dependencies();
	$self->add_volatile_prices_dependency($self->{'args'}->get_arg_values($calc, $i, 1));
    }
	
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
  
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $prices = $calc->prices;
    my $diff = 0;
    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	$diff = $self->{'args'}->get_arg_values($calc, $n, 2) - 
	  $self->{'args'}->get_arg_values($calc, $n-1, 2);
	# Add the won points
	if ($diff > 0) {
	  $sum_of_won_points += $diff;
	}
	# Add the lost points
	if ($diff < 0) {
	  $sum_of_lost_points -= $diff;
	}
    }

    if ($sum_of_lost_points != 0) {
       $rs = $sum_of_won_points / $sum_of_lost_points;
    }
    
    $rsi = 100 - (100 / (1 + $rs));
    $calc->indicators->set($name, $i, $rsi);
}
