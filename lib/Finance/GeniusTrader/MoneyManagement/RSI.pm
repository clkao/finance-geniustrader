package GT::MoneyManagement::RSI;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Indicators::RSI;
use GT::Prices;
use GT::Portfolio;

@NAMES = ("RSI");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::RSI

=head2 Overview

This new money management technique utilize the Relative Strength Index
(RSI) in order to improve the performance of trend-following trading.

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

    $self->{'rsi'} = GT::Indicators::RSI->new([ 10 ]);
    $self->add_indicator_dependency($self->{'rsi'}, 1);
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $indic = $calc->indicators;
    my $rsi_name = $self->{'rsi'}->get_name;
    my $factor = 0;
    
    return if (! $self->check_dependencies($calc, $i));
    
    if (defined($order->quantity)) {
	
	my $rsi = $indic->get($rsi_name, $i);
	
	if ($order->is_buy_order) {
	    $factor = (100 - $rsi) / 100;
	}
	if ($order->is_sell_order) {
	    $factor = $rsi / 100;
	}
	return int($order->quantity * $factor);
    }
}

1;
