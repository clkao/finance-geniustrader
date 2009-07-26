package Finance::GeniusTrader::MoneyManagement::STO;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::MoneyManagement;
use Finance::GeniusTrader::Indicators::STO;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Portfolio;

@NAMES = ("STO");
@ISA = qw(Finance::GeniusTrader::MoneyManagement);

=head1 Finance::GeniusTrader::MoneyManagement::STO

=head2 Overview

This new money management technique utilize the Stochastics (STO) in order
to improve the performance of trend-following trading.

=head2 References

"A New Money Management Technique" - Takehide Matoba
Article found in http://www.erivativesreview.com

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub initialize {
    my $self = shift;

    $self->{'sto'} = Finance::GeniusTrader::Indicators::STO->new([ 10 ]);
    $self->add_indicator_dependency($self->{'sto'}, 1);
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $indic = $calc->indicators;
    my $sto_name = $self->{'sto'}->get_name(3);
    my $factor = 0;
    
    return if (! $self->check_dependencies($calc, $i));
    
    if (defined($order->quantity)) {
	
	my $sto = $indic->get($sto_name, $i);
	
	if ($order->is_buy_order) {
	    $factor = (100 - $sto) / 100;
	}
	if ($order->is_sell_order) {
	    $factor = $sto / 100;
	}
	return int($order->quantity * $factor);
    }
}

1;
