package Finance::GeniusTrader::CloseStrategy::Stop::Breakeven;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::CloseStrategy;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::CloseStrategy);
@NAMES = ("Breakeven[#1,#2]");
@DEFAULT_ARGS = (5, 2);

=head1 Finance::GeniusTrader::CloseStrategy::Stop::Breakeven

=head2 Overview

This strategy place a stop order when we reach a profit target, to be sure
that if things are going wrong we will never let a winning trade become a
losing one ! The stop should be calculated by including commission &
slippage.

=cut

sub initialize {
    my ($self) = @_;
}

sub get_indicative_long_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;

    return 0;
}

sub get_indicative_short_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;
    
    return 0;
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'long_profit_factor'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    $self->{'long_stop_factor'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 2) / 100;
    if ($calc->prices->at($i)->[$LAST] >= ($position->open_price * $self->{'long_profit_factor'})) {
	$position->set_stop($position->open_price * $self->{'long_stop_factor'});
    }
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'short_profit_factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    $self->{'short_stop_factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 2) / 100;
    if ($calc->prices->at($i)->[$LAST] <= ($position->open_price * $self->{'short_profit_factor'})) {
        $position->set_stop($position->open_price * $self->{'short_stop_factor'});
    }
    return;
}

1;
