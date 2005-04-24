package GT::DateTime::Day;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

use GT::DateTime;
#ALL# use Log::Log4perl qw(:easy);
use POSIX;

=head1 GT::DateTime::Day

This module treat dates describing a day. They have the following format :
YYYY-MM-DD

=cut
sub map_date_to_time {
    my ($date) = @_;
    my ($y, $m, $d) = split /-/, $date;
    return POSIX::mktime(0, 0, 0, $d, $m - 1, $y - 1900);
}

sub map_time_to_date {
    my ($time) = @_;
    my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime($time);
    return sprintf("%04d-%02d-%02d", $y + 1900, $m + 1, $d);
}

sub timeframe_ratio {
    my ($tf) = @_;
    
    #WAR# WARN "timeframe must be smaller than a day" unless ($tf < $DAY);
    
    $tf == $PERIOD_1MIN && return 8 * 60; # 8 hours approximatively
    $tf == $PERIOD_2MIN && return 8 * 30; # 2 times less
    $tf == $PERIOD_5MIN && return 8 * 12;
    $tf == $PERIOD_10MIN && return 8 * 6;
    $tf == $PERIOD_30MIN && return 8 * 2;
    $tf == $HOUR && return 8;
}

1;
