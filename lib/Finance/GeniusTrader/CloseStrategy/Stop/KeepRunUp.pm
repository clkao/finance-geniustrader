package Finance::GeniusTrader::CloseStrategy::Stop::KeepRunUp;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::CloseStrategy;
use Finance::GeniusTrader::Indicators::Generic::MaxInPeriod;
use Finance::GeniusTrader::Indicators::Generic::MinInPeriod;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::CloseStrategy);
@NAMES = ("KeepRunUp[#*]");
@DEFAULT_ARGS = (10, "{I:Prices LOW}", "{I:Prices HIGH}", "{I:Prices CLOSE}");

=head1 Finance::GeniusTrader::CloseStrategy::Stop::KeepRunUp

=head2 Overview

This strategy closes the position once the prices have crossed the
trailing stop defined as a percentage below the highest high value for a
long trade or above the highest low value for a short trade, called the
"run up", since the trade is open. The purpose of this strategy is to keep
opening profits and avoid to turn profitable trades into loosing ones.

=cut

sub get_indicative_long_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;
    my $percentage = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $close = $self->{'args'}->get_arg_values($calc, $i, 4);
    
    return ($close * (1 - $percentage / 100));
}

sub get_indicative_short_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;
    my $percentage = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $close = $self->{'args'}->get_arg_values($calc, $i, 4);

    return ($close * (1 + $percentage / 100));
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
    my $percentage = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $date = $position->open_date;
    my $code = $position->code;
    my $prices = $calc->prices;
    
    if ($i >= $prices->date($date)) {

	my $max = Finance::GeniusTrader::Indicators::Generic::MaxInPeriod->new([$date,
							     $self->{'args'}->get_arg_names(3) ]);
        $max->calculate($calc, $i);
	
        my $highest_high = $calc->indicators->get($max->get_name, $i);
	$position->set_stop($highest_high * (1 - $percentage / 100));
    }

    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    my $percentage = $self->{'args'}->get_arg_values($calc, $i, 1);

    my $date = $position->open_date;
    my $code = $position->code;
    my $prices = $calc->prices;

    if ($i >= $prices->date($date)) {

	my $min = Finance::GeniusTrader::Indicators::Generic::MinInPeriod->new([$date,
							     $self->{'args'}->get_arg_names(2) ]);
	$min->calculate($calc, $i);

        my $lowest_low = $calc->indicators->get($min->get_name, $i);
	$position->set_stop($lowest_low * (1 + $percentage / 100));
    }

    return;
}

1;
