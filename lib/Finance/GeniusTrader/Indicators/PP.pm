package Finance::GeniusTrader::Indicators::PP;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::TP;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("Pivot[#*]", "FirstSupport[#*]", "SecondSupport[#*]", "FirstResistance[#*]", "SecondResistance[#*]");
@DEFAULT_ARGS = ("{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 Finance::GeniusTrader::Indicators::PP

=head2 Overview

Pivot Points and Daily Support and Resistance.

=head2 Calculation

The calculation for the new day are calculated from the High (H), low (L) and close (C) of the previous day.
Pivot point = P = (H + L + C)/3
First area of resistance = R1 = 2P - L
First area of support = S1 = 2P - H
Second area of resistance = R2 = (P -S1) + R1
Second area of support = S2 = P - (R1 - S1)

=head2 Links

http://www.sixer.com/y/s/education/tutorial/edpage.cfm?f=pivots.cfm&OB=indicators
http://www.tradertalk.com/tutorial/Pivpt.html

=cut

sub initialize {
    my $self = shift;
 
    $self->{'tp'} = Finance::GeniusTrader::Indicators::TP->new( [ $self->{'args'}->get_arg_names(1),
					       $self->{'args'}->get_arg_names(2),
					       $self->{'args'}->get_arg_names(3)
					     ] );
 
    $self->add_indicator_dependency($self->{'tp'}, 2);
    $self->add_prices_dependency(2);
}

=head2 Finance::GeniusTrader::Indicators::PP::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $prices = $calc->prices;
    my $indic = $calc->indicators;
    my $pivot_name = $self->get_name(0);
    my $first_support_name = $self->get_name(1);
    my $second_support_name = $self->get_name(2);
    my $first_resistance_name = $self->get_name(3);
    my $second_resistance_name = $self->get_name(4);

    # Return if results are already available
    return if ($indic->is_available($pivot_name, $i) &&
               $indic->is_available($first_support_name, $i) &&
	       $indic->is_available($second_support_name, $i) &&
	       $indic->is_available($first_resistance_name, $i) &&
	       $indic->is_available($second_resistance_name, $i));
    
    # Return if dependencies are missing
    return if (! $self->check_dependencies($calc, $i));

    # Get the Pivot Point which is the Typical Price
    # in the "traditional" calculation method
    my $pivot = $indic->get($self->{'tp'}->get_name, $i - 1);
    
    # Calculate supports and resistances
    my $first_resistance = (2 * $pivot) - $self->{'args'}->get_arg_values($calc, $i-1, 2);
    my $first_support = (2 * $pivot) - $self->{'args'}->get_arg_values($calc, $i-1, 1);
    my $second_resistance = ($pivot - $first_support) + $first_resistance;
    my $second_support = $pivot - ($first_resistance - $first_support);

    # Then return results
    $calc->indicators->set($pivot_name, $i, $pivot);
    $calc->indicators->set($first_support_name, $i, $first_support);
    $calc->indicators->set($second_support_name, $i, $second_support);
    $calc->indicators->set($first_resistance_name, $i, $first_resistance);
    $calc->indicators->set($second_resistance_name, $i, $second_resistance);

}

1;
