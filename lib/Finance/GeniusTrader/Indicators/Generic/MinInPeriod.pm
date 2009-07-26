package Finance::GeniusTrader::Indicators::Generic::MinInPeriod;

# Copyright 2000-2002 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Tools qw(:math);

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("MinInPeriod[#*]");
@DEFAULT_ARGS = (2, "{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::Generic::MinInPeriod - Calculate a mimimum

=head1 DESCRIPTION

This indicator calculates the minimum of any serie of data in the
last XX days or since a given date.

=head1 PARAMETERS

=over

=item Number of days / date

You can specify either a number or a date. In the first case the minimum will
be calculated with the last <number> days. In the second case it will be the minimum
since the given date.

=item Data

This is the data to use as input. If you don't specify anything, the
closing price will be used by default.

=back

Example of accepted argument list :

=over

=item 10 {I:RSI}

=item 2005-01-03

=item 5

=item 2005-04-05 {I:Prices LOW}

=item "2005-04-05 14:30:00" {I:Prices LOW}

=back

=cut
sub initialize {
    my ($self) = @_;
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    
    return if ($calc->indicators->is_available($name, $i));

    my $res = undef;
    my $arg = $self->{'args'}->get_arg_values($calc, $i, 1);

    if ($arg =~ /^\d+$/) {
	$res = $self->{'args'}->get_arg_values($calc, $i, 2);
	for (my $n = 1; $n < $arg; $n++) {
	    my $val = $self->{'args'}->get_arg_values($calc, $i - $n, 2);
	    if (defined($val) && defined($res)) {
		$res = min($res, $val);
	    }
	}
    } elsif ($arg =~/^\d{4}-\d\d(-\d\d)?( \d\d:\d\d:\d\d)?$/) {
	my $n = undef;
	if ($calc->prices->has_date($arg)) {
	    $n = $calc->prices->date($arg);
	} else {
	    $n = $calc->prices->date($calc->prices->find_nearest_date($arg));
	}
	if ($i >= $n) {
	    $res = $self->{'args'}->get_arg_values($calc, $n++, 2);
	    for(;$n <= $i; $n++) {
		my $val = $self->{'args'}->get_arg_values($calc, $n, 2);
		if (defined($val)) {
		    $res = min($res, $val);
		}
	    }
	}
    }
    
    if (defined($res)) {
	$calc->indicators->set($name, $i, $res);
    }
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    my $name = $self->get_name;

    ($first, $last) = $self->update_interval($calc, $first, $last);
    return if ($calc->indicators->is_available_interval($name, $first, $last));

    my $arg = $self->{'args'}->get_arg_names(1);
    my $currentLow;

    if ($arg =~ /^\d+$/) {
        my $period = $arg;
	return if (! $self->check_dependencies_interval($calc, $first - $period, $last));
	$currentLow = $self->{'args'}->get_arg_values($calc, $first - $period, 2);
        for (my $i = $first - $period; $i < $first; $i++) {
	    my $currentValue = $self->{'args'}->get_arg_values($calc, $i, 2);
	    if ($currentValue < $currentLow) {
	    	$currentLow = $currentValue;
	    }
	}
        for (my $i = $first; $i <= $last; $i++) {
	    my $currentValue = $self->{'args'}->get_arg_values($calc, $i, 2);
	    my $oldestValue = $self->{'args'}->get_arg_values($calc, $i - $period, 2);
	    if ($oldestValue == $currentLow) {
	        # find new low between ($i-$period..$i)
		my $tempLow;
	    	$currentLow = $self->{'args'}->get_arg_values($calc, $i - $period + 1, 2);
	        for (my $j = $i - $period + 1; $j < $i; $j++) {
	        	$tempLow = $self->{'args'}->get_arg_values($calc, $j, 2);
			if ($tempLow < $currentLow) {
				$currentLow = $tempLow;
			}
		}
	    }
	    if ($currentValue < $currentLow) {
	    	$currentLow = $currentValue;
	    }
	    $calc->indicators->set($name, $i, $currentLow);
        }
    } elsif ($arg =~/^\d{4}-\d\d(-\d\d)?( \d\d:\d\d:\d\d)?$/) {
	my $n = undef;
	if ($calc->prices->has_date($arg)) {
	    $n = $calc->prices->date($arg);
	} else {
	    $n = $calc->prices->date($calc->prices->find_nearest_date($arg));
	}
	if ($n > $first) {
	    $first = $n;
	}
	return if (! $self->check_dependencies_interval($calc, ($first > $n) ? $n : $first, $last));
	$currentLow = $self->{'args'}->get_arg_values($calc, $n, 2);
	for (my $i = $n; $i < $first; $i++) {
	    my $currentValue = $self->{'args'}->get_arg_values($calc, $i, 2);
	    if ($currentValue < $currentLow) {
	        $currentLow = $currentValue;
	    }
	}
	for (my $i = $first; $i <= $last; $i++) {
	    my $currentValue = $self->{'args'}->get_arg_values($calc, $i, 2);
            if ($currentValue < $currentLow) {
	        $currentLow = $currentValue;
	    }
	    $calc->indicators->set($name, $i, $currentLow);
	}
    }
}
