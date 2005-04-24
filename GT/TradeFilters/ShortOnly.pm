package GT::TradeFilters::ShortOnly;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@NAMES @ISA @DEFAULT_ARGS);

use GT::TradeFilters;
use Carp::Datum;

@NAMES = ("ShortOnly");
@ISA = qw(GT::TradeFilters);
@DEFAULT_ARGS = ();

=head1 NAME

GT::TradeFilters::ShortOnly - Only allow short trades

=head1 DESCRIPTION

This filter allows only short trades and reject long ones. This filter is
a must to find if a system perform better as a short only system than
either a long only or a long and short trading system.

=cut

sub accept_trade {
    DFEATURE my $f;
    my ($self, $order, $i, $calc, $portfolio) = @_;
    
    if ($order->is_sell_order) {
	return DVAL 1;
    } else {
	return DVAL 0;
    }
}

1;
