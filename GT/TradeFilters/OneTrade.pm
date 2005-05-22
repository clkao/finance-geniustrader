package GT::TradeFilters::OneTrade;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@NAMES @ISA @DEFAULT_ARGS);

use GT::TradeFilters;

@NAMES = ("SingleTrade");
@ISA = qw(GT::TradeFilters);
@DEFAULT_ARGS = ();

=head1 NAME

GT::TradeFilters::OneTrade - Refuse simultaneous trades

=head1 DESCRIPTION

This filter refuses a new trade if a position is actually open. It will
however accept it if it's in the process of being closed.

=cut

sub accept_trade {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    
    my @pos = $portfolio->list_open_positions($order->source);
    foreach (@pos)
    {
	if ($_->code eq $order->code)
	{
	    if (! $_->being_closed)
	    {
		return 0;
	    }
	}
    }
    return 1;
}

1;
