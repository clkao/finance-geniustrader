package Finance::GeniusTrader::MoneyManagement::Basic;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::MoneyManagement;
use Finance::GeniusTrader::Prices;

@NAMES = ("Basic");
@ISA = qw(Finance::GeniusTrader::MoneyManagement);

=head1 Finance::GeniusTrader::MoneyManagement::Basic

Basic and dumb money management rules. Invest all cash available (provided
that no marged position block the cash - in this money management rule
each dollar invested in marged position requires 1 dollar in cash).

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [] };
 
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    
    my $date = $calc->prices->at($i)->[$DATE];
    if ($portfolio->has_historic_evaluation($date)) {
	my ($cash, $eval, $gains, $minvest) = $portfolio->get_historic_evaluation($date);
	my $avail = $cash + $gains - $minvest;
	foreach my $pos ($portfolio->list_open_positions()) {
	    # Tread marged positions like usual position
	    if ($pos->being_closed()) {
		$avail += $portfolio->{'position_evaluation'}{$pos->id};
		# Note that we forget cash needed to pay the close order
		# but hey ... we're already not sure of tomorrow's
		# evaluation.
	    }
	}
	my $price = (defined($order->{'price'})) ? $order->{'price'} : $calc->prices->at($i)->[$LAST];
	if ($avail > $price) {
	    return int($avail / $price);
	} else {
	    return 0;
	}
    }
    # No way to decide following our rules
    if (defined($order->{'quantity'}) &&
        $order->{'quantity'})
    {
        return $order->{'quantity'};
    }
    return 0;
    
}

