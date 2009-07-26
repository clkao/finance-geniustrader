package Finance::GeniusTrader::Signals::Prices::RecordPriceHigh;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

# Standards-Version: 1.0

use Finance::GeniusTrader::Signals;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::Generic::MaxInPeriod;

@ISA = qw(Finance::GeniusTrader::Signals);
@NAMES = ("RecordPriceHigh[#*]");
@DEFAULT_ARGS = ("30", "{I:Prices HIGH}");

sub initialize {
    my ($self) = @_;
    
    $self->{'max'} = Finance::GeniusTrader::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_constant(1) - 1, $self->{'args'}->get_arg_names(2) ]);

    $self->add_indicator_dependency($self->{'max'}, 2);
    $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $q = $calc->prices;
    my $max_name = $self->{'max'}->get_name;

    return if ($calc->signals->is_available($self->get_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # We're doing a new high
    if ( $self->{'args'}->get_arg_values($calc, $i, 2) > $calc->indicators->get($max_name, $i - 1) ) {
        $calc->signals->set($self->get_name, $i, 1);
    } else {
        $calc->signals->set($self->get_name, $i, 0);
    }
}

1;
