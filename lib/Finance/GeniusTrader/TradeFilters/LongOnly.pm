package Finance::GeniusTrader::TradeFilters::LongOnly;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@NAMES @ISA @DEFAULT_ARGS);

use Finance::GeniusTrader::TradeFilters;

@NAMES = ("LongOnly");
@ISA = qw(Finance::GeniusTrader::TradeFilters);
@DEFAULT_ARGS = ();

=head1 NAME

Finance::GeniusTrader::TradeFilters::LongOnly - Only allow long trades

=head1 DESCRIPTION

This filter allows only long trades and reject short ones. This is
especially usefull for people who don't want to short the market.
Moreover, this filter is a must to find if a system perform better as a long
only system than either a short only or a long and short trading system.

=cut

sub accept_trade {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    
    if ($order->is_buy_order) {
	return 1;
    } else {
	return 0;
    }
}

1;
