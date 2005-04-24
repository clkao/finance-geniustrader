package GT::DateTime::Year;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

use GT::DateTime;
#ALL# use Log::Log4perl qw(:easy);
use POSIX;

=head1 GT::DateTime::Year

This module treat dates describing a year. They have the following format :
YYYY

=cut
sub map_date_to_time {
    my ($date) = @_;
    return POSIX::mktime(0, 0, 0, 1, 0, $date - 1900);
}

sub map_time_to_date {
    my ($time) = @_;
    my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime($time);
    return sprintf("%04d", $y + 1900);
}

sub timeframe_ratio {
    my ($tf) = @_;

    #WAR# WARN "timeframe must be smaller than a year" unless ($tf < $YEAR);

    $tf == $MONTH && return 12;
    $tf == $WEEK  && return 52;
    $tf == $DAY   && return 250;
    return GT::DateTime::timeframe_ratio($DAY, $tf) * 250;
}

1;
