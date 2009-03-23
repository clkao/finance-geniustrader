package GT::Indicators::Generic::MaxInPeriod;

# Copyright 2000-2002 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);

@ISA = qw(GT::Indicators);
@NAMES = ("MaxInPeriod[#*]");
@DEFAULT_ARGS = (2, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::Generic::MaxInPeriod - Calculate a maximum

=head1 DESCRIPTION

This indicator calculates the maximum of any serie of data in the
last XX days or since a given date.

=head1 PARAMETERS

=over

=item Number of days / date

You can specify either a number or a date. In the first case the maximum will
be calculated with the last <number> days. In the second case it will be the maximum
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

=item 2005-04-05 {I:Prices HIGH}

=item "2005-04-05 14:30:00" {I:Prices HIGH}

=back

=cut
sub initialize {
    my ($self) = @_;
    $self->add_arg_dependency(1, 1) unless $self->{'args'}->is_constant(1);
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    my $name = $self->get_name;

    ($first, $last) = $self->update_interval($calc, $first, $last);
    return if ($calc->indicators->is_available_interval($name, $first, $last));
    
    my $arg = $self->{'args'}->get_arg_names(1);
    my $currentHigh;

    if ($arg =~ /^[\d.]+$/) {
        my $period = $arg;
	return if (! $self->check_dependencies_interval($calc, $first - $period, $last));
	$currentHigh = $self->{'args'}->get_arg_values($calc, $first - $period, 2);
        for (my $i = $first - $period; $i < $first; $i++) {
	    my $currentValue = $self->{'args'}->get_arg_values($calc, $i, 2);
	    if ($currentValue > $currentHigh) {
	    	$currentHigh = $currentValue;
	    }
	}
        for (my $i = $first; $i <= $last; $i++) {
	    my $currentValue = $self->{'args'}->get_arg_values($calc, $i, 2);
	    my $oldestValue = $self->{'args'}->get_arg_values($calc, $i - $period, 2);
	    if ($oldestValue == $currentHigh) {
	        # find new high between ($i-$period..$i)
		my $tempHigh;
	    	$currentHigh = $self->{'args'}->get_arg_values($calc, $i - $period + 1, 2);
	        for (my $j = $i - $period + 1; $j < $i; $j++) {
	        	$tempHigh = $self->{'args'}->get_arg_values($calc, $j, 2);
			if ($tempHigh > $currentHigh) {
				$currentHigh = $tempHigh;
			}
		}
	    }
	    if ($currentValue > $currentHigh) {
	    	$currentHigh = $currentValue;
	    }
	    $calc->indicators->set($name, $i, $currentHigh);
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
	$currentHigh = $self->{'args'}->get_arg_values($calc, $n, 2);
	for (my $i = $n; $i < $first; $i++) {
	    my $currentValue = $self->{'args'}->get_arg_values($calc, $i, 2);
	    if ($currentValue > $currentHigh) {
	        $currentHigh = $currentValue;
	    }
	}
	for (my $i = $first; $i <= $last; $i++) {
	    my $currentValue = $self->{'args'}->get_arg_values($calc, $i, 2);
            if ($currentValue > $currentHigh) {
	        $currentHigh = $currentValue;
	    }
	    $calc->indicators->set($name, $i, $currentHigh);
	}
    }
    else {
	GT::Indicators::calculate_interval(@_);
    }
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $res = undef;
    my $arg = $self->{'args'}->get_arg_values($calc, $i, 1);
    Carp::cluck unless defined $arg;
    if ($arg =~ /^[\d.]+$/) {
	$res = $self->{'args'}->get_arg_values($calc, $i, 2);
	for (my $n = 1; $n < $arg; $n++) {
            return if $i - $n < 0;
	    my $val = $self->{'args'}->get_arg_values($calc, $i - $n, 2);
	    if (defined($val) && defined($res)) {
		$res = max($res, $val);
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
		    $res = max($res, $val);
		}
	    }
	}
    }

    if (defined($res)) {
	$calc->indicators->set($name, $i, $res);
    }
}
