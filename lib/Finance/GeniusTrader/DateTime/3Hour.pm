package Finance::GeniusTrader::DateTime::3Hour;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Copyright 2005 João Antunes Costa
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

use Finance::GeniusTrader::DateTime;
use Time::Local;

=head1 Finance::GeniusTrader::DateTime::3Hour

This module treat dates describing the 3Hour timeframe. They have the following format :
YYYY-MM-DD HH:00:00

=cut
sub map_date_to_time {
    my ($value) = @_;
	my ($date, $time) = split / /, $value;
    my ($y, $m, $d) = split /-/, $date;
	$time = "00:00:00" if (!defined($time));
	my ($h, , ) = split /:/, $time;
	if ($h >=21) {$h=21}
	elsif ($h>=18) {$h=18}
	elsif ($h>=15) {$h=15}
	elsif ($h>=12) {$h=12}
	elsif ($h>=9) {$h=9}
	elsif ($h>=6) {$h=6}
	elsif ($h>=3) {$h=3}
	else {$h=0}
    return timelocal(0, 0, $h, $d, $m - 1, $y - 1900);
}

sub map_time_to_date {
    my ($time) = @_;
    my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime($time);

	if ($hour>=21) {$hour=21;}
	elsif ($hour>=18) {$hour=18;}
	elsif ($hour>=15) {$hour=15;}
	elsif ($hour>=12) {$hour=12;}
	elsif ($hour>=9) {$hour=9;}
	elsif ($hour>=6) {$hour=6;}
	elsif ($hour>=3) {$hour=3;}
	else {$hour=0;}

    return sprintf("%04d-%02d-%02d %02d:00:00", $y + 1900, $m + 1, $d, $hour);
}

1;
