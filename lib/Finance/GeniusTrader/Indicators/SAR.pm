package GT::Indicators::SAR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::Generic::MinInPeriod;
use GT::Indicators::Generic::MaxInPeriod;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("SAR[#*]");
@DEFAULT_ARGS = (0.02, 0.02, 0.2, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 GT::Indicators::SAR

=head2 Overview

The Parabolic SAR, developed by Welles Wilder, is used to set trailing
price stops.  SAR refers to "Stop-And-Reversal".  It is designed to create
exit points for both long and short positions in such a way that it allows
for reactions or fluctuations at the beginning of the position, but
accelerates upward (for long positions) or downward (for short positions)
as the movement tops out.

=head2 Calculation

If Long :
SAR(i) = SAR(i-1) + Acceleration Factor *
         (Extreme Point of the current position - SAR(i-1))

Wilder's acceleration factor (AF) is 0.02 for the initial calculation.
Thereafter the AF is increased 0.02 every period there is a New High made.
If a new high is not made then the AF is not increased from the last SAR.
This continues until the AF reaches 0.2. Once the AF reaches 0.2 it
stays at that value for all future SAR calculations until the trade is
stopped out.


If Short :
SAR(i) = SAR(i-1) - Acceleration Factor *
         (Extreme Point of the current position - SAR(i-1))

The AF is initially 0.02 and changes by 0.02 intervals until it is 0.2 but
the change in the AF is made only after each New Low of a period is made.
The AF is never increased above 0.2.

=head2 Parameters

Most softwar packages only allow the user to vary the acceleration factor
increment and the acceleration factor maximum, fixing the starting
acceleration factor at 0.02. This restriction hampers the trend-following
abilities of the parabolic, so don't be surprised if GeniusTrader is going
a little step further and let you set up your own initial acceleration
factor.

=head2 Links

http://www.stockcharts.com/education/Resources/Glossary/parabolicSAR.html
http://www.equis.com/free/taaz/parabolicsar.html
http://www.linnsoft.com/tour/techind/sar.htm

=cut

sub initialize {
    my $self = shift;

    $self->{'min'} = GT::Indicators::Generic::MinInPeriod->new([ 3, $self->{'args'}->get_arg_names(6) ]);
    $self->{'max'} = GT::Indicators::Generic::MaxInPeriod->new([ 3, $self->{'args'}->get_arg_names(6) ]);
    
    $self->add_indicator_dependency($self->{'min'}, 1);
    $self->add_indicator_dependency($self->{'max'}, 1);
    $self->add_arg_dependency(4, 5);
    $self->add_arg_dependency(5, 5);
    $self->add_arg_dependency(6, 5);
}

=head2 GT::Indicators::SAR::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $prices = $calc->prices;
    my $indic = $calc->indicators;
    my $sar_name = $self->get_name;
    my $initial_acceleration_factor = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $incremental_acceleration_factor = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $maximum_acceleration_factor = $self->{'args'}->get_arg_values($calc, $i, 3);
    my $min_name = $self->{'min'}->get_name;
    my $max_name = $self->{'max'}->get_name;
    my $acceleration_factor = $initial_acceleration_factor;
    my $position = 0;
    my $new_position = 0;
    my $extreme_price_period;
    my $previous_sar_value = 0;
    my $sar_value = 0;
    my ($min, $max);

    # Return if results are already available or dependencies missing
    return if ($indic->is_available($sar_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # Let us start with a long position based on the observation that
    # this high extended beyond the two previous highs during a minor
    # trading range.

    if (($self->{'args'}->get_arg_values($calc, $i, 4) > $self->{'args'}->get_arg_values($calc, $i-1, 4)) and
	($self->{'args'}->get_arg_values($calc, $i, 4) > $self->{'args'}->get_arg_values($calc, $i-1, 4))) {
	$position = 1;
    }

    # Initialize $min and $max
    $min = $indic->get($min_name, $i);
    $max = $indic->get($max_name, $i);
 
    # The first SAR value is calculated by taking the difference between
    # the high price and the low price and multiplying the difference by
    # the initial acceleration factor.
 
    if ($position == 1) {
	$previous_sar_value = $min + $acceleration_factor * ($max - $min);
	$extreme_price_period = $min;
    } else {
	$previous_sar_value = $max - $acceleration_factor * ($max - $min);
	$extreme_price_period = $max;
    }

    for (my $j = $i; $j < $prices->count(); $j++) {

	# Stay aware of each SAR reversal !
	if ($position == 1) {
	    if ($self->{'args'}->get_arg_values($calc, $j, 6) <= $previous_sar_value) {

		# Update $position and $new_position values
		$new_position = 1;
		$position = 0;

		# Initialize the first SAR value with the extreme price
		# of the last period
		$sar_value = $extreme_price_period;
		
	    } else {
		$new_position = 0;
	    }
	} else {
	    if ($self->{'args'}->get_arg_values($calc, $j, 6) >= $previous_sar_value) {

		# Update $position and $new_position values		
		$new_position = 1;
		$position = 1;

		# Initialize the first SAR value with the extreme price
		# of the last period
		$sar_value = $extreme_price_period;
		
	    } else {
		$new_position = 0;
	    }
	}

	if ($new_position == 1) {

	    # Initialize the acceleration factor to it's initial value
	    # each time we switch from a long to a short position or vice
	    # versa.
	    
	    $acceleration_factor = $initial_acceleration_factor;
	    
	} else {

	    # Increment the acceleration factor each time a new high or a new
	    # low appears. Update extreme price period value.
	
	    if ($position == 1) {
		if ($self->{'args'}->get_arg_values($calc, $j, 4) > $extreme_price_period ) {
		    $acceleration_factor += $incremental_acceleration_factor;
		    $extreme_price_period = $self->{'args'}->get_arg_values($calc, $j, 4);
		}
	    } else {
		if ($self->{'args'}->get_arg_values($calc, $j, 5) < $extreme_price_period ) {
		    $acceleration_factor += $incremental_acceleration_factor;
		    $extreme_price_period = $self->{'args'}->get_arg_values($calc, $j, 5);
		}
	    }

	    # Be sure the acceleration remains below the maximum level
	    if ($acceleration_factor > $maximum_acceleration_factor) {
		$acceleration_factor = $maximum_acceleration_factor;
	    }

	    # Calculate SAR value if it's not the first value of a new trend
	    if ($new_position == 0) {
		$sar_value = $previous_sar_value + $acceleration_factor *
                             ($extreme_price_period - $previous_sar_value);
	    }
	}

	# Update $previous_sar_value with $sar_value
	$previous_sar_value = $sar_value;
	
	# Store every new SAR value
	$calc->indicators->set($sar_name, $j, $sar_value);
    }
}

1;
