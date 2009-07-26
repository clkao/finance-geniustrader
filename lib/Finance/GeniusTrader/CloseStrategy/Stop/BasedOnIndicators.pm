package Finance::GeniusTrader::CloseStrategy::Stop::BasedOnIndicators;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::CloseStrategy;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Tools qw(:generic);

@ISA = qw(Finance::GeniusTrader::CloseStrategy);
@NAMES = ("BasedOnIndicators[#*]");
@DEFAULT_ARGS = ("{I:SMA}", "{I:SMA}", "{I:Prices CLOSE}");

=head1 Finance::GeniusTrader::CloseStrategy::Stop::BasedOnIndicators

=head2 Overview

This strategy end up a position once prices have crossed the trailing stop
determined by indicators.

=cut

sub initialize {
    my ($self) = @_;
}

sub get_indicative_long_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;

    return 0 if (! $self->check_dependencies($calc, $i));
    my $indi = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $price = $self->{'args'}->get_arg_values($calc, $i, 3);

    if ($indi < $price) {
        return $indi;
    } else {
	return 0;
    }
}

sub get_indicative_short_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;

    return 0 if (! $self->check_dependencies($calc, $i));
    my $indi = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $price = $self->{'args'}->get_arg_values($calc, $i, 3);

    if ($indi > $price) {
	return $indi;
    } else {
	return 0;
    }
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

    return if (! $self->check_dependencies($calc, $i));
    my $indi = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $price = $self->{'args'}->get_arg_values($calc, $i, 3);

    if ($indi < $price) {
	$position->set_stop($indi);
    }
    
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return if (! $self->check_dependencies($calc, $i));
    my $indi = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $price = $self->{'args'}->get_arg_values($calc, $i, 3);

    if ($indi > $price) {
	$position->set_stop($indi);
    }

    return;
}

1;
