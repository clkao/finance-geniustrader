package Finance::GeniusTrader::Signals::Prices::Unchange;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

# Standards-Version: 1.0

use Finance::GeniusTrader::Signals;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Signals);
@NAMES = ("Unchange");
@DEFAULT_ARGS = ();

=head1 NAME

Finance::GeniusTrader::Signals::Unchange

=head1 DESCRIPTION

The Unchange Signal will be able to tell you if a security is unchange or not from the previous period.

Advance, Decline and Unchange Signals are basics signals and will be your row materials for designing lots of market indicators.

=cut
sub initialize {
    my ($self) = @_;
    
    $self->add_prices_dependency(2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $q = $calc->prices;

    return if ($calc->signals->is_available($self->get_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # We're not moving !
    if ( $q->at($i)->[$LAST] == $q->at($i-1)->[$LAST] ) {
        $calc->signals->set($self->get_name, $i, 1);
    } else {
        $calc->signals->set($self->get_name, $i, 0);
    }
}

1;
