package Finance::GeniusTrader::CloseStrategy::Stop::Fixed;

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
@NAMES = ("StopFixed[#1]");
@DEFAULT_ARGS = (4);

=head1 Finance::GeniusTrader::CloseStrategy::Stop::Fixed

This strategy closes the position once the prices have crossed a limit
called stop. This stop is defined as a percentage from the initial price.
The limit is parameterized. By default it's 4%.

=cut

sub initialize {
    my ($self) = @_;
}

sub get_indicative_long_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;
    my $stop = 0;
    $self->{'long_factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    if ($order->price)
    {
	$stop = $order->price * $self->{'long_factor'};
    } else {
	$stop = $calc->prices->at($i)->[$LAST] * $self->{'long_factor'};
    }
    return $stop;
}

sub get_indicative_short_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;
    my $stop = 0;
    $self->{'short_factor'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    if ($order->price)
    {
	$stop = $order->price * $self->{'short_factor'};
    } else {
	$stop = $calc->prices->at($i)->[$LAST] * $self->{'short_factor'};
    }
    return $stop;
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'long_factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    $position->set_stop($position->open_price * $self->{'long_factor'});
    
    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'short_factor'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    $position->set_stop($position->open_price * $self->{'short_factor'});

    return;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $ps_manager, $sys_manager) = @_;
    
    return;
}

