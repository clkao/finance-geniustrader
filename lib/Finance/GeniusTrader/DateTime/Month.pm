package Finance::GeniusTrader::DateTime::Month;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

use Finance::GeniusTrader::DateTime;
#ALL# use Log::Log4perl qw(:easy);
use Time::Local;

=head1 Finance::GeniusTrader::DateTime::Month

This module treat dates describing a month. They have the following format :
YYYY-MM

=cut
sub map_date_to_time {
    my ($date) = @_;
    my ($y, $m) = split /\//, $date;
    return timelocal(0, 0, 0, 1, $m - 1, $y - 1900);
}

sub map_time_to_date {
    my ($time) = @_;
    my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime($time);
    return sprintf("%04d/%02d", $y + 1900, $m + 1);
}

sub timeframe_ratio {
    my ($tf) = @_;

    #WAR# WARN "timeframe must be smaller than a month" unless ($tf < $MONTH);

    $tf == $DAY && return 30 * 5 / 7;
    $tf == $WEEK && return 30 / 7;
    return Finance::GeniusTrader::DateTime::timeframe_ratio($DAY, $tf) * 30 * 5 / 7;
}

1;
