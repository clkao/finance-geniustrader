package GT::PricesTools;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT $DAILY $MONTHLY $YEARLY $WEEKLY);
use GT::Prices;
use Date::Calc qw(Date_to_Days Day_of_Week Week_Number);

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw($DAILY $MONTHLY $YEARLY $WEEKLY multiply_prices_by_number divide_prices_by_number convert_prices_in_a_new_time_frame reverse_prices select_prices_by_period);

$DAILY = 0;
$MONTHLY = 1;
$YEARLY = 2;
$WEEKLY = 3;

=head1 NAME

GT::PricesTools - Utility functions for manipulating GT::Prices

=head1 DESCRIPTION

This package provide some simple functions to merge data from an existing
GT::Prices to a new GT::Prices object. It's especially usefull to convert
daily data to a new time frame (ie: weekly/monthly).

=head2 Examples

  convert_prices_in_a_new_time_frame($prices, $WEEKLY);
  select_prices_by_period($prices, "2000-01-01", "2000-12-31");

  multiply_prices_by_number($prices, 3.45);
  divide_prices_by_number($prices, 2.5);

  reverse_prices($prices)

=head2 Ideas for later

  adjust prices by the last rate of a currency
  adjust prices by daily historical rate of a currency

=cut

sub convert_prices_in_a_new_time_frame {
    my ($prices, $time_frame) = @_;
    my $period = 0;
    my $new_period = 0;
    my $new_period_name = "";
    my $last_period_name = "";
    my $start = 0;
    my ($open, $high, $low, $close, $volume, $date) = 0;

    # Return if we don't have enouth parameters
    return if not $prices;
    return if !$time_frame;
    
    my $quotes = GT::Prices->new();

    for (my $i = 0; $i < $prices->count(); $i++) {

	# Split the date from the database to something usable
	my ($year, $month, $day) = split(/-/, $prices->at($i)->[$DATE]);

	# Initialize period
	if ($time_frame eq $DAILY) {
	    $period = $day;
	}
	if ($time_frame eq $MONTHLY) {
	    $period = $month;
	}
	if ($time_frame eq $YEARLY) {
	    $period = $year;
	}
	if ($time_frame eq $WEEKLY) {
	    $period = Date_to_Days($year, $month, $day) - Day_of_Week($year, $month, $day);
	}
	
	# Check if the current price is in the current period or not
	if ($new_period_name eq $period) {
	    $new_period = 0;
	} else {
	    $new_period_name = $period;
	    $new_period = 1;
	}

        # Add a record in the new time frame, for a finished period
	if ($i > 0) {
	    if ($new_period eq 1) {
		$open = $prices->at($start)->[$OPEN];
		$close = $prices->at($i - 1)->[$CLOSE];
		$quotes->add_prices([ $open, $high, $low, $close, $volume, $date ]);
		$start = $i;
		$high = $low = $volume = 0;
	    }
	}
	
	# Initialize date according to the specified time frame
	if (($new_period_name eq $period) or ($date eq 0)) {
	    if ($time_frame eq $DAILY) {
		$date = $year . "-" . $month . "-" . $day;
	    }
	    if ($time_frame eq $MONTHLY) {
		$date = $year . "-" . $month;
	    }
	    if ($time_frame eq $YEARLY) {
		$date = $year;
	    }
	    if ($time_frame eq $WEEKLY) {
		$date = $year . "-" . Week_Number($year, $month, $day);
	    }
	}

	# Calculate $high, $low and $volume
	if ((!$high) or ($high eq 0) or ($prices->at($i)->[$HIGH] > $high)) {
	    $high = $prices->at($i)->[$HIGH];
	}
	if ((!$low) or ($low eq 0) or ($prices->at($i)->[$LOW] < $low)) {
	    $low = $prices->at($i)->[$LOW];
	}
	$volume += $prices->at($i)->[$VOLUME];

	# Add a record in the new time frame, for the last and not yet
	# finished period
	if ($i eq ($prices->count() - 1)) {
	    $open = $prices->at($start)->[$OPEN];
	    $close = $prices->at($i)->[$CLOSE];
	    $quotes->add_prices([ $open, $high, $low, $close, $volume, $date ]);
	}	    
    }
    return $quotes;
}

sub select_prices_by_period {
    my ($prices, $first_date, $last_date) = @_;
    my $quotes = GT::Prices->new();

    # Initialize $first_date to the first record's date and $last_date to the last record's date
    # if these arguments are not available
    if (!$first_date) {
	$first_date = $prices->at(0)->[$DATE];
    }
    if (!$last_date) {
	$last_date = $prices->at($prices->count() - 1)->[$DATE];
    }
    
    # Split $first_date and $last_date to something usable
    my ($first_date_year, $first_date_month, $first_date_day) = split(/-/, $first_date);
    my ($last_date_year, $last_date_month, $last_date_day) = split(/-/, $last_date);
    
    for (my $i = 0; $i < $prices->count(); $i++) {

	# Split record's date to something usable
	my ($year, $month, $day) = split(/-/, $prices->at($i)->[$DATE]);

	# Add a record in the new GT::Prices object if (First Date < Record's Date) and (Record's Date < Last Date)
	if ( (Date_to_Days($first_date_year, $first_date_month, $first_date_day) <= Date_to_Days($year, $month, $day)) and
	     (Date_to_Days($year, $month, $day) <= Date_to_Days($last_date_year, $last_date_month, $last_date_day)) ) {

	    $quotes->add_prices([ $prices->at($i)->[$OPEN], $prices->at($i)->[$HIGH], $prices->at($i)->[$LOW], $prices->at($i)->[$CLOSE], $prices->at($i)->[$VOLUME], $prices->at($i)->[$DATE] ]);
	}
    }
    return $quotes;
}

sub multiply_prices_by_number {
    my ($prices, $number) = @_;
    my $quotes = GT::Prices->new();
    
    for (my $i = 0; $i < $prices->count(); $i++) {
	$quotes->add_prices([ ($prices->at($i)->[$OPEN] * $number), ($prices->at($i)->[$HIGH] * $number), ($prices->at($i)->[$LOW] * $number), ($prices->at($i)->[$CLOSE] * $number), ($prices->at($i)->[$VOLUME] * $number), $prices->at($i)->[$DATE] ]);
    }
    return $quotes;    
}

sub divide_prices_by_number {
    my ($prices, $number) = @_;
    my $quotes = GT::Prices->new();

    for (my $i = 0; $i < $prices->count(); $i++) {
	$quotes->add_prices([ ($prices->at($i)->[$OPEN] / $number), ($prices->at($i)->[$HIGH] / $number), ($prices->at($i)->[$LOW] / $number), ($prices->at($i)->[$CLOSE] / $number), ($prices->at($i)->[$VOLUME] / $number), $prices->at($i)->[$DATE] ]);
    }
    return $quotes;
}

sub reverse_prices {
    my ($prices) = @_;
    my $quotes = GT::Prices->new();
    my $max = $prices->count();
    
    for (my $i = 0; $i < $max; $i++) {
	my $n = $max - $i - 1;
	$quotes->add_prices([ $prices->at($n)->[$OPEN], $prices->at($n)->[$HIGH], $prices->at($n)->[$LOW], $prices->at($n)->[$CLOSE], $prices->at($n)->[$VOLUME], $prices->at($n)->[$DATE] ]);
    }
    return $quotes;
}

1;
