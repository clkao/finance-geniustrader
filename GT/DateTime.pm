package GT::DateTime;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT $PERIOD_TICK $PERIOD_1MIN $PERIOD_5MIN $PERIOD_10MIN
	    $PERIOD_15MIN $PERIOD_30MIN $HOUR $PERIOD_3HOUR $DAY $WEEK $MONTH $YEAR %NAMES);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($PERIOD_TICK $PERIOD_1MIN $PERIOD_5MIN $PERIOD_10MIN
	     $PERIOD_15MIN $PERIOD_30MIN $HOUR $PERIOD_3HOUR $DAY $WEEK $MONTH $YEAR);

#ALL#  use Log::Log4perl qw(:easy);

$PERIOD_TICK = 1;
$PERIOD_1MIN = 10;
$PERIOD_5MIN = 30;
$PERIOD_10MIN = 40;
$PERIOD_15MIN = 45;
$PERIOD_30MIN = 50;
$HOUR = 60;
$PERIOD_3HOUR = 64;
$DAY = 70;
$WEEK = 80;
$MONTH = 90;
$YEAR = 100;

%NAMES = (
    $PERIOD_TICK => "tick",
    $PERIOD_1MIN => "1min",
    $PERIOD_5MIN => "5min",
    $PERIOD_10MIN => "10min",
    $PERIOD_15MIN => "15min",
    $PERIOD_30MIN => "30min",
    $HOUR => "hour",
    $PERIOD_3HOUR => "3hour",
    $DAY => "day",
    $WEEK => "week",
    $MONTH => "month",
    $YEAR => "year"
);

require GT::DateTime::Tick;
require GT::DateTime::1Min;
require GT::DateTime::5Min;
require GT::DateTime::10Min;
require GT::DateTime::15Min;
require GT::DateTime::30Min;
require GT::DateTime::Hour;
require GT::DateTime::3Hour;
require GT::DateTime::Day;
require GT::DateTime::Week;
require GT::DateTime::Month;
require GT::DateTime::Year;

=head1 NAME

GT::DateTime - Manage TimeFrames and provides date/time helper functions

=head1 DESCRIPTION

This module exports all the variable describing the available "periods"
commonly used for trading : $PERIOD_TICK $PERIOD_1MIN, $PERIOD_5MIN,
$PERIOD_10MIN, $PERIOD_15MIN, $PERIOD_30MIN, $HOUR, $PERIOD_3HOUR, $DAY, $WEEK, $MONTH, $YEAR.

The timeframes are represented by those variables which are only numbers.
You can compare those numbers to know which timeframe is smaller or which
one is bigger.

It also provides several functions to manipulate dates and periods. Those
functions use modules GT::DateTime::* to do the actual work depending on
the selected timeframe.

=head2 Functions provided by submodules

map_date_to_time($date) is a function returning a time (ie a number of
seconds since 1970) representing that date in the history. It is usually
corresponding to the first second of the given period.

map_time_to_date($time) is the complementary function. It will return a
date describing the period that includes the given time.

=head2 Functions

=over

=item C<< GT::DateTime::map_date_to_time($timeframe, $date) >>

=item C<< GT::DateTime::map_time_to_date($timeframe, $time) >>

Those are the generic functions used to convert a date into a time and vice
versa.

=cut
sub map_date_to_time {
    my ($timeframe, $date) = @_;

    $timeframe == $PERIOD_TICK && return GT::DateTime::Tick::map_date_to_time($date);
    $timeframe == $PERIOD_1MIN && return GT::DateTime::1Min::map_date_to_time($date);
    $timeframe == $PERIOD_5MIN && return GT::DateTime::5Min::map_date_to_time($date);
    $timeframe == $PERIOD_10MIN && return GT::DateTime::10Min::map_date_to_time($date);
    $timeframe == $PERIOD_15MIN && return GT::DateTime::15Min::map_date_to_time($date);
    $timeframe == $PERIOD_30MIN && return GT::DateTime::30Min::map_date_to_time($date);
    $timeframe == $HOUR  && return GT::DateTime::Hour::map_date_to_time($date);
    $timeframe == $PERIOD_3HOUR  && return GT::DateTime::3Hour::map_date_to_time($date);
    $timeframe == $DAY   && return GT::DateTime::Day::map_date_to_time($date);
    $timeframe == $WEEK  && return GT::DateTime::Week::map_date_to_time($date);
    $timeframe == $MONTH && return GT::DateTime::Month::map_date_to_time($date);
    $timeframe == $YEAR  && return GT::DateTime::Year::map_date_to_time($date);
}

sub map_time_to_date {
    my ($timeframe, $time) = @_;

    $timeframe == $PERIOD_TICK && return GT::DateTime::Tick::map_time_to_date($time);
    $timeframe == $PERIOD_1MIN && return GT::DateTime::1Min::map_time_to_date($time);
    $timeframe == $PERIOD_5MIN && return GT::DateTime::5Min::map_time_to_date($time);
    $timeframe == $PERIOD_10MIN && return GT::DateTime::10Min::map_time_to_date($time);
    $timeframe == $PERIOD_15MIN && return GT::DateTime::15Min::map_time_to_date($time);
    $timeframe == $PERIOD_30MIN && return GT::DateTime::30Min::map_time_to_date($time);
    $timeframe == $HOUR  && return GT::DateTime::Hour::map_time_to_date($time);
    $timeframe == $PERIOD_3HOUR  && return GT::DateTime::3Hour::map_time_to_date($time);
    $timeframe == $DAY   && return GT::DateTime::Day::map_time_to_date($time);
    $timeframe == $WEEK  && return GT::DateTime::Week::map_time_to_date($time);
    $timeframe == $MONTH && return GT::DateTime::Month::map_time_to_date($time);
    $timeframe == $YEAR  && return GT::DateTime::Year::map_time_to_date($time);
}

=item C<< GT::DateTime::convert_date($date, $orig_timeframe, $dest_timeframe) >>

This function does convert the given date from the $orig_timeframe in a
date of the $dest_timeframe. Take care that the destination timeframe must be
bigger than the original timeframe.

=cut
sub convert_date {
    my ($date, $orig, $dest) = @_;
    #WAR#  WARN  "the destination time frame must be bigger" if ( $orig <= $dest);
    return map_time_to_date($dest, map_date_to_time($orig, $date));
}

=item C<< GT::DateTime::list_of_timeframe() >>

Returns the list of timeframes that are managed by the DateTime framework.

=cut
sub list_of_timeframe {
    return (
	    $PERIOD_TICK, $PERIOD_1MIN, $PERIOD_5MIN, $PERIOD_10MIN,
	    $PERIOD_15MIN, $PERIOD_30MIN, $HOUR, $PERIOD_3HOUR,
	    $DAY, $WEEK, $MONTH, $YEAR
	   );
}

=item C<< GT::DateTime::name_of_timeframe($tf) >>

Return the official name of the corresponding timeframe.

=cut
sub name_of_timeframe {
    my ($tf) = @_;
    return $NAMES{$tf};
}

=item C<< GT::DateTime::name_to_timeframe($name) >>

Returns the timeframe associated to the given name.

=cut
sub name_to_timeframe {
    my ($name) = @_;
    foreach (keys %NAMES)
    {
	if ($NAMES{$_} eq $name)
	{
	    return $_;
	}
    }
    return undef;
}

=item C<< GT::DateTime::timeframe_ratio($first, $second) >>

Returns how many times the second timeframe fits in the first one.

=cut
sub timeframe_ratio {
    my ($first, $second) = @_;
    return 1 if ($first == $second);
    if ($first < $second)
    {
	return (1 / timeframe_ratio($second, $first));
    }

	$first == $PERIOD_TICK && die("Cannot set timeframe ratio for tick data");
    $first == $PERIOD_1MIN && return (GT::DateTime::Hour::timeframe_ratio($second) / 60);
    $first == $PERIOD_5MIN && return (GT::DateTime::Hour::timeframe_ratio($second) / 12);
    $first == $PERIOD_10MIN && return (GT::DateTime::Hour::timeframe_ratio($second) / 6);
    $first == $PERIOD_15MIN && return (GT::DateTime::Hour::timeframe_ratio($second) / 4);
    $first == $PERIOD_30MIN && return (GT::DateTime::Hour::timeframe_ratio($second) / 2);
    $first == $HOUR && return GT::DateTime::Hour::timeframe_ratio($second);
    $first == $PERIOD_3HOUR && return (GT::DateTime::Hour::timeframe_ratio($second) * 3);
    $first == $DAY && return GT::DateTime::Day::timeframe_ratio($second);
    $first == $WEEK && return GT::DateTime::Week::timeframe_ratio($second);
    $first == $MONTH && return GT::DateTime::Month::timeframe_ratio($second);
    $first == $YEAR && return GT::DateTime::Year::timeframe_ratio($second);
}

=pod

=back

=cut
1;
