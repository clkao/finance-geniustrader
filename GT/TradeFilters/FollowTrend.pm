package GT::TradeFilters::FollowTrend;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@NAMES @ISA @DEFAULT_ARGS);

use GT::TradeFilters;
use GT::Indicators::SMA;
use Carp::Datum;

@NAMES = ("FollowTrend[#1]");
@ISA = qw(GT::TradeFilters);
@DEFAULT_ARGS = (50);

=head1 NAME

GT::TradeFilters::FollowTrend - Allow only trades following the direction of an SMA

=head1 DESCRIPTION

This filter tries to limit the risks by refusing trades againts the
market (ie like buying in a bear market or selling in a bullish market).

The first parameter is the number of days used to calculate the SMA.

=cut

sub initialize {
    DFEATURE my $f;
    my ($self) = @_;
    
    $self->{'mm'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names(1) ]);
    
    $self->add_indicator_dependency($self->{'mm'}, 2);
    
    return DVOID;
}

sub accept_trade {
    DFEATURE my $f;
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $mm_name = $self->{'mm'}->get_name;
    
    # Refuse if we can't evaluate the risk
    return DVAL 0 if (! $self->check_dependencies_interval($calc, $i - 1, $i));

    if ($calc->indicators->get($mm_name, $i-1) <
	$calc->indicators->get($mm_name, $i))
    {
	# Bull market
	if ($order->is_buy_order())
	{
	    return DVAL 1;
	} else {
	    return DVAL 0;
	}
    } else {
	# Bear market
	if ($order->is_sell_order())
	{
	    return DVAL 1;
	} else {
	    return DVAL 0;
	}
    }
}

1;
