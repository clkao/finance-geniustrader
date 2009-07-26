package Finance::GeniusTrader::TradeFilters::Generic;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::TradeFilters;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::Tools qw(:generic);

@ISA = qw(Finance::GeniusTrader::TradeFilters);
@NAMES = ("Generic[#*]");
@DEFAULT_ARGS = ("{S:Generic:False}", "{S:Generic:False}");

=head1 NAME

TradeFilters::Generic - Accept or refuse trades based on specific signals

=head1 DESCRIPTION

This tradefilter takes two signals as parameter. The first decides if a buy
order is allowed, the second one decides if a sell order is allowed. If 
you don't precise a parameter, the corresponding orders will be refused.

=head1 EXAMPLES

Allow buy orders only when SMA 20 is moving up and sell orders when
SMA 20 is decreasing :

  TF:Generic {S:Generic:Increase {I:SMA 20}} {S:Generic:Decrease {I:SMA 20}}

=cut


sub initialize {
    my ($self) = @_;

    $self->add_arg_dependency(1, 1);
    $self->add_arg_dependency(2, 1);
}

sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;

    $self->{'args'}->prepare_interval($calc, $first, $last);
}

sub accept_trade {
    my ($self, $order, $i, $calc, $portfolio) = @_;

    return if (! $self->check_dependencies($calc, $i));

    if ($order->is_buy_order()) {
	# Buy order, allow only if first signal is true
	if ($self->{'args'}->get_arg_values($calc, $i, 1)) {
	    return 1;
	} else {
	    return 0;
	}
    } else {
	# Sell order, allow only if second signal is true
	if ($self->{'args'}->get_arg_values($calc, $i, 2)) {
	    return 1;
	} else {
	    return 0;
	}
    }
}

1;
