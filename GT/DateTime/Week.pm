package GT::DateTime::Week;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

use GT::DateTime;
use Date::Calc qw(Week_of_Year Monday_of_Week);
#ALL# use Log::Log4perl qw(:easy);
use POSIX;

=head1 GT::DateTime::Week

This module treat dates describing a week. They have the following format :
YYYY-WW

WW being the week number.

=cut
sub map_date_to_time {
    my ($date) = @_;
    my ($y, $w) = split /-/, $date;
    my ($year, $month, $day) = Monday_of_Week($w, $y);
    return POSIX::mktime(0, 0, 0, $day, $month - 1, $year - 1900);
}

sub map_time_to_date {
    my ($time) = @_;
    my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime($time);
    #DEB# DEBUG "$time => $y-$m-$d";
    my ($week, $year) = Week_of_Year($y + 1900, $m + 1, $d);
    return sprintf("%04d-%02d", $year, $week);
}

sub timeframe_ratio {
    my ($tf) = @_;

    #WAR# WARN "timeframe must be smaller than a week" unless ($tf < $WEEK);

    $tf == $DAY && return 5;
    return GT::DateTime::timeframe_ratio($DAY, $tf) * 5;
}

1;
