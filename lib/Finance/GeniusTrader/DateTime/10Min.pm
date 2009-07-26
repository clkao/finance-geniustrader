package GT::DateTime::10Min;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Copyright 2005 João Antunes Costa
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

use GT::DateTime;
use Time::Local;

=head1 GT::DateTime::10Min

This module treat dates describing a 10 minute period. They have the following format :
YYYY-MM-DD HH:N0:00

=cut
sub map_date_to_time {
    my ($value) = @_;
	my ($date, $time) = split / /, $value;
    my ($y, $m, $d) = split /-/, $date;
	my ($h, $n, ) = split /:/, $time;
	if ($n >=50) {$n=50}
	elsif ($n>=40) {$n=40}
	elsif ($n>=30) {$n=30}
	elsif ($n>=20) {$n=20}
	elsif ($n>=10) {$n=10}
	else {$n=0}
    return timelocal(0, $n, $h, $d, $m - 1, $y - 1900);
}

sub map_time_to_date {
    my ($time) = @_;
    my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime($time);
	if ($min>=50) {$min=50;}
	elsif ($min>=40) {$min=40;}
	elsif ($min>=30) {$min=30;}
	elsif ($min>=20) {$min=20;}
	elsif ($min>=10) {$min=10;}
	else {$min=0;}
    return sprintf("%04d-%02d-%02d %02d:%02d:00", $y + 1900, $m + 1, $d, $hour, $min);
}

1;
