package Finance::GeniusTrader::Signals::Prices::GapUp;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

# Standards-Version: 1.0

use Finance::GeniusTrader::Signals;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Signals);
@NAMES = ("GapUp[#1]");
@DEFAULT_ARGS = (0);

=head1 NAME

Finance::GeniusTrader::Signals::GapUp

=head1 DESCRIPTION

Gaps form when opening price movements create a blank spot on the chart.
Gaps are especially significant when accompanied by an increase of volume.

An up gap forms when a security opens above previous period's high, remains
above the previous high for the entire period and close above it.

Up gaps can form on daily, weekly or monthly charts and are generally considered bullish.

=cut

sub initialize {
    my ($self) = @_;
    
    $self->add_prices_dependency(2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $q = $calc->prices;
    my $percentage = ($self->{'args'}->get_arg_values($calc, $i, 1) / 100);

    return if ($calc->signals->is_available($self->get_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # A Gap Up appears when the lowest price of the period
    # is above the highest price of the previous period.
    if ( $q->at($i)->[$LOW] > ($q->at($i-1)->[$HIGH] * (1 + $percentage))) {
        $calc->signals->set($self->get_name, $i, 1);
    } else {
        $calc->signals->set($self->get_name, $i, 0);
    }
}

1;
