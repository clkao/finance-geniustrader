package GT::DateTime::30Min;

# Copyright 2005 João Antunes Costa
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

use GT::DateTime;
#ALL# use Log::Log4perl qw(:easy);
use POSIX;

=head1 GT::DateTime::30Min

This module treat dates describing an half-hour. They have the following format :
YYYY-MM-DD HH:N0:00

=cut
sub map_date_to_time {
    my ($value) = @_;
	my ($date, $time) = split / /, $value;
    my ($y, $m, $d) = split /-/, $date;
	my ($h, $n, ) = split /:/, $time;
	if ($n >=30) {$n=30;} else {$n=0;}
    return POSIX::mktime(0, $n, $h, $d, $m - 1, $y - 1900);
}

sub map_time_to_date {
    my ($time) = @_;
    my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime($time);
	if ($min>=30) {$min=30;} else {$min=0;}
    return sprintf("%04d-%02d-%02d_%02d:%02d:00", $y + 1900, $m + 1, $d, $hour, $min);
}

1;
