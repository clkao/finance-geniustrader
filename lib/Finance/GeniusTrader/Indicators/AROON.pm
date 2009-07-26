package GT::Indicators::AROON;

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
@NAMES = ("AroonUp[#*]","AroonDown[#*]","AroonOsc[#*]");
@DEFAULT_ARGS = (25, "{I:Prices HIGH}", "{I:Prices LOW}");

=head2 GT::Indicators::AROON

=head2 Overview

Developed by Tushar Chande in 1995, the Aroon is an indicator system that can be used to determine whether a stock is trending or not and how strong the trend is. "Aroon" means "Dawn's Early Light" in Sanskrit and Chande choose that name for this indicator since it is designed to reveal the beginning of a new trend.

The Aroon indicator consists of two lines, Aroon(up) and Aroon(down). The Aroon Oscillator is a single line that is defined as the difference between Aroon(up) and  Aroon(down). All three take a single parameter which is the number of time periods to use in the calculation. Since Aroon(up) and Aroon(down) both oscillate between 0 and +100, the Aroon Oscillator ranges from -100 to +100 with zero serving as the crossover line.

=head2 Calculation

Aroon(up) for a given time period is calculated by determining how much time (on a percentage basis) elapsed between the start of the time period and the point at which the highest closing price during that time period occurred. When the stock is setting new highs for the time period, Aroon(up) will be 100. If the stock has moved lower every day during the time period, Aroon(up) will be zero. Aroon(down) is calculated in just the opposite manner, looking for new lows instead of new highs.

=head2 Examples

GT::Indicators::AROON->new()
GT::Indicators::AROON->new([20])

=head2 Validation

This indicators is validated by the values from comdirect.de.
The stock used was the DAX (data from yahoo) at the 04.06.2003:

AroonUp[25]         [2003-06-04] = 100.0000 (comdirect: 100.0)
AroonDown[25]       [2003-06-04] = 76.0000  (comdirect: 76.0)
AroonOsc[25]        [2003-06-04] = 24.0000  (comdirect: 24.0)

=head2 Links

http://stockcharts.com/education/resources/glossary/aroon.html
http://www.paritech.com/education/technical/indicators/trend/aroon.asp
http://www.geocities.com/WallStreet/Floor/1035/aroon.htm

=cut

sub initialize {
    my $self = shift;

    my $mstr = "{I:Generic:Eval " .$self->{'args'}->get_arg_names(1) . " + 1}";
    $self->{'min'} = GT::Indicators::Generic::MinInPeriod->new([ $mstr,
								 $self->{'args'}->get_arg_names(3) ] );
    $self->{'max'} = GT::Indicators::Generic::MaxInPeriod->new([ $mstr,
								 $self->{'args'}->get_arg_names(2) ] );

    $self->add_indicator_dependency($self->{'min'}, 1);
    $self->add_indicator_dependency($self->{'max'}, 1);
}

=head2 GT::Indicators::AROON::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $aroon_up_name = $self->get_name(0);
    my $aroon_down_name = $self->get_name(1);
    my $aroon_osc_name = $self->get_name(2);
    my $min = $self->{'min'};
    my $max = $self->{'max'};
    my $last_period_high = 0;
    my $last_period_low = 0;

    return if ($indic->is_available($aroon_up_name, $i) &&
	       $indic->is_available($aroon_down_name, $i) &&
	       $indic->is_available($aroon_osc_name, $i));

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2,$period+1);
    $self->add_volatile_arg_dependency(3,$period+1);
    return if (! $self->check_dependencies($calc, $i));
    
    # Get Min and Max
    my $min_value = $indic->get($min->get_name, $i);
    my $max_value = $indic->get($max->get_name, $i);
    
    for (my $n = $i - $period; $n <= $i; $n++) {

        # Last period high
	if ($self->{'args'}->get_arg_values($calc, $n, 2) eq $max_value) {
	    $last_period_high = $n;
	}
	# Last period low
	if ($self->{'args'}->get_arg_values($calc, $n, 3) eq $min_value) {
	    $last_period_low = $n;
	}
    }

    my $aroon_up_value = (($period - ($i - $last_period_high)) / $period * 100);
    my $aroon_down_value = (($period - ($i - $last_period_low)) / $period * 100);
    my $aroon_osc_value = $aroon_up_value - $aroon_down_value;

    # Return the results
    $indic->set($aroon_up_name, $i, $aroon_up_value);
    $indic->set($aroon_down_name, $i, $aroon_down_value);
    $indic->set($aroon_osc_name, $i, $aroon_osc_value);
}

1;
