package Finance::GeniusTrader::TradeFilters::AroonTrend;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@NAMES @ISA @DEFAULT_ARGS);

use Finance::GeniusTrader::TradeFilters;
use Finance::GeniusTrader::Indicators::AROON;

@NAMES = ("AroonTrend");
@ISA = qw(Finance::GeniusTrader::TradeFilters);
@DEFAULT_ARGS = ();

=head1 NAME

Finance::GeniusTrader::TradeFilters::AroonTrend - Allow only trades following the trend defined by Aroon

=head1 DESCRIPTION

This filter  tries to limit the risks by refusing trades againts the
market (ie like buying in a bear market or selling in a bullish market).

=cut

sub initialize {
    my ($self) = @_;
    
    $self->{'aroon'} = Finance::GeniusTrader::Indicators::AROON->new;
    return;
}

sub accept_trade {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $name = $self->{'aroon'}->get_name(2);
    
    $self->{'aroon'}->calculate($calc, $i);

    if (! $calc->indicators->is_available($name, $i))
    {
	# Refuse if we can't evaluate the risk
	return 0;
    }

    if (abs($calc->indicators->get($name, $i)) > 30)
    {
	return 0;
    } else {
	# Authorize when there's no clear trend
	return 1;
    }
}

1;
