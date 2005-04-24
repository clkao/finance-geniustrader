package GT::Indicators::CCI;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::SMA;
use GT::Indicators::TP;

@ISA = qw(GT::Indicators);
@NAMES = ("CCI[#*]");
@DEFAULT_ARGS = (20, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 GT::Indicators::CCI

=head2 Overview

Developed by Donald Lambert, the Commodity Channel Index (CCI) was designed to identify cyclical turns in commodities. The assumption behind the indicator is that commodities (or stocks or bonds) move in cycles, with highs and lows coming at periodic intervals.

=head2 Calculation

There are 4 steps involved in the calculation of the CCI :
1. Calculate the last period's Typical Price (TP) = (H+L+C)/3 where H = high, L = low, and C = close.
2. Calculate the 20-period Simple Moving Average of the Typical Price (SMATP).
3. Calculate the Mean Deviation. First, calculate the absolute value of the difference between the last period's SMATP and the typical price for each of the past 20 periods. Add all of these absolute values together and divide by 20 to find the Mean Deviation.
4. The final step is to apply the Typical Price (TP), the Simple Moving Average of the Typical Price (SMATP), the Mean Deviation and a Constant (.015) to the following formula :

CCI = ( (Typical Price - Simple Moving Average of the Typical Price) / (0.015 * Mean Deviation))

=head2 Parameters

Lambert recommended using 1/3 of a complete cycle (low to low or high to high) as a time frame for the CCI. Note that the determination of the cycle's length is independent of the CCI. If the cycle runs 60 days (a low about every 60 days), then a 20-day CCI would be recommended.

=head2 Example

GT::Indicators::CCI->new()
GT::Indicators::CCI->new([25])

=head2 Note

Traders and investors use the CCI to help identify price reversals, price extremes and trend strength. As with most indicators, the CCI should be used in conjunction with other aspects of technical analysis. CCI fits into the momentum category of oscillators.

=head2 Validation

This Indicator was validated by the data available from comdirect.de: 
The DAX at 04.06.2003 (data from yahoo.com) had a CCI of 158.71
This is consistent with this indicator: 158.7057

=head2 Links

http://www.equis.com/free/taaz/cci.html
http://www.stockcharts.com/education/What/IndicatorAnalysis/indic_CCI.html
http://www.finance-net.com/apprendre/techniques/cci.phtml

=cut

sub initialize {
    my $self = shift;

    my $tp = "{I:TP " . $self->{'args'}->get_arg_names(2) . " " .
      $self->{'args'}->get_arg_names(3) . " " .
	$self->{'args'}->get_arg_names(4) . "}";
    $self->{'tp'} = GT::Indicators::TP->new( [ $self->{'args'}->get_arg_names(2),
					       $self->{'args'}->get_arg_names(3),
					       $self->{'args'}->get_arg_names(4)
					     ] );
    $self->{'sma'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names(1), $tp ]);
}

=head2 GT::Indicators::CCI::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $tp = $self->{'tp'};
    my $sma = $self->{'sma'};
    my $tp_name = $tp->get_name;
    my $sma_name = $sma->get_name;
    my $cci_name = $self->get_name(0);
    my $tp_value = 0;
    my $sum_of_diff = 0;

    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency( $self->{'sma'}, $period );
    $self->add_volatile_indicator_dependency( $self->{'tp'}, $period );
    $self->add_volatile_prices_dependency($period * 2);

    return if ($indic->is_available($cci_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # Get the Simple Moving Average of the Typical Price
    my $smatp = $indic->get($sma_name, $i);

    for (my $m = $i - $period + 1; $m <= $i; $m++) {
        # Get the Typical Price
	$tp_value = $indic->get($tp_name, $m);
	$smatp = $indic->get($sma_name, $m);
	
        # Calculate the difference between the Typical Price and today's Simple Moving Average of the Typical Price
	$sum_of_diff += abs($tp_value - $smatp);
    }

    # Calculate the Mean Deviation
    my $mean_deviation = $sum_of_diff / ($period);

    # Calculate the CCI
    my $cci = ($tp_value - $smatp) / (0.015 * ($mean_deviation));

    # Return the result
    $indic->set($cci_name, $i, $cci);

}

1;
