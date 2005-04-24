package GT::TradeFilters::MaxOpenTrades;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@NAMES @ISA @DEFAULT_ARGS);

use GT::TradeFilters;
use Carp::Datum;

@NAMES = ("MaxOpenTrades[#1]");
@ISA = qw(GT::TradeFilters);
@DEFAULT_ARGS = (4);

=head1 NAME

GT::TradeFilters::MaxOpenTrades - Refuse more than N trades

=head1 DESCRIPTION

This filter refuses a new trade if more than N positions are open. It will
however accept it if it's in the process of being closed.

=cut

sub accept_trade {
    DFEATURE my $f;
    my ($self, $order, $i, $calc, $portfolio) = @_;
    
    my @pos = $portfolio->list_open_positions($order->source);
    my $trades = 0;
    foreach (@pos)
    {
	if ($_->code eq $order->code)
	{
	    if (! $_->being_closed)
	    {
		$trades++;
	    }
	}
    }

    if ($trades >= $self->{'args'}->get_arg_constant(1)) {
    	return DVAL 0;
    }

    return DVAL 1;
}

1;
