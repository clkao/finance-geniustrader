package Finance::GeniusTrader::Signals::Generic::NewTimeFrame;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Signals;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::DateTime;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Tools qw(:generic);

@ISA = qw(Finance::GeniusTrader::Signals);
@NAMES = ("NewTimeFrame[#*]");
@DEFAULT_ARGS = ("month");

=head1 NewTimeFrame Generic Signal

=head2 Overview

This signal will tell you when you entered a new timeframe
(e.g. the next month/week/year).

=cut

sub initialize {
    my ($self) = @_;
    $self->add_prices_dependency( 1 );
    $self->{'special_tf'} = Finance::GeniusTrader::DateTime::name_to_timeframe($self->{'args'}->get_arg_constant(1));
}

sub detect {
    my ($self, $calc, $i) = @_;

    return if (! $self->check_dependencies($calc, $i));
    return if ($calc->signals->is_available($self->get_name, $i));

    my $today = $calc->prices->at($i)->[$DATE];
    my $yesterday = $calc->prices->at($i-1)->[$DATE];

    my $time = Finance::GeniusTrader::DateTime::map_date_to_time($calc->prices->timeframe(), $today);
    $today   = Finance::GeniusTrader::DateTime::map_time_to_date($self->{'special_tf'}, $time);

    $time      = Finance::GeniusTrader::DateTime::map_date_to_time($calc->prices->timeframe(), $yesterday);
    $yesterday = Finance::GeniusTrader::DateTime::map_time_to_date($self->{'special_tf'}, $time);

    if ( $today ne $yesterday ) {
	$calc->signals->set($self->get_name, $i, 1);
    } else {
	$calc->signals->set($self->get_name, $i, 0);
    }
}

1;
