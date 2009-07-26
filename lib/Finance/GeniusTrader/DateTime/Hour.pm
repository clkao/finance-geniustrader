package GT::DateTime::Hour;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Copyright 2005 João Antunes Costa
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

use GT::DateTime;
#ALL# use Log::Log4perl qw(:easy);
use Time::Local;

=head1 GT::DateTime::Hour

This module treat dates describing an Hour. They have the following format :
YYYY-MM-DD HH:00:00

=cut
sub map_date_to_time {
    my ($value) = @_;
	my ($date, $time) = split / /, $value;
    my ($y, $m, $d) = split /-/, $date;
	$time = "00:00:00" if (!defined($time));
	my ($h, , ) = split /:/, $time;
    return timelocal(0, 0, $h, $d, $m - 1, $y - 1900);
}

sub map_time_to_date {
    my ($time) = @_;
    my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime($time);
    return sprintf("%04d-%02d-%02d %02d:00:00", $y + 1900, $m + 1, $d, $hour);
}

sub timeframe_ratio {
    my ($tf) = @_;

    #WAR# WARN "timeframe must be smaller than an hour" unless ($tf < $HOUR);
    $tf == $PERIOD_1MIN && return 60; # 8 hours approximatively
    $tf == $PERIOD_5MIN && return 12;
    $tf == $PERIOD_10MIN && return 6;
    $tf == $PERIOD_30MIN && return 2;
	$tf == $HOUR && return 1;
}

1;
