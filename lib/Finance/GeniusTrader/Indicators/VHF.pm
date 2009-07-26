package Finance::GeniusTrader::Indicators::VHF;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::Generic::MinInPeriod;
use Finance::GeniusTrader::Indicators::Generic::MaxInPeriod;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("VHF[#*]");
@DEFAULT_ARGS = (28, "{I:Prices CLOSE}");

=head1 Finance::GeniusTrader::Indicators::VHF

=head2 Overview

The Vertical Horizontal Filter (VHF) can tell you whether a market is going through a trending or congestion phase, and whether you should use trend-following indicators if the markets are trending or congestion-phase indicators if markets are in a trading range.

=head2 Calculation

VHF = (Highest Close (n) - Lowest Close (n)) / (Sum of absolute value of the one-day price change for the range (n))

=head2 Parameters

The standard VHF works with a 28-days parameter : n = 28

=head2 Example

Finance::GeniusTrader::Indicators::VHF->new()
Finance::GeniusTrader::Indicators::VHF->new([50])

=head2 Links

http://www.equis.com/free/taaz/verthorizfilter.html
http://www.finance-net.com/apprendre/techniques/vhf.phtml

=cut
sub initialize {
    my $self = shift;

    $self->{'min'} = Finance::GeniusTrader::Indicators::Generic::MinInPeriod->new([ $self->{'args'}->get_arg_names(1), $self->{'args'}->get_arg_names(2) ]);
    $self->{'max'} = Finance::GeniusTrader::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_names(1), $self->{'args'}->get_arg_names(2) ]);

    $self->add_indicator_dependency($self->{'min'}, 1);
    $self->add_indicator_dependency($self->{'max'}, 1);
    $self->add_prices_dependency($self->{'args'}->get_arg_names(1));
}

=head2 Finance::GeniusTrader::Indicators::VHF::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $period = $self->{'args'}->get_arg_names(1);
    my $min = $self->{'min'};
    my $max = $self->{'max'};
    my $min_name = $min->get_name;
    my $max_name = $max->get_name;
    my $vhf_name = $self->get_name(0);
    my $sum_of_one_day_price_change = 0;

    return if ($indic->is_available($vhf_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # Get Highest Close and Lowest Close values
    my $lowest_close = $indic->get($min_name, $i);
    my $highest_close = $indic->get($max_name, $i);

    for (my $n = $i - $period + 1; $n <= $i; $n++) {
        # Calculate the sum of absolute value of the one-day price change over the period
        $sum_of_one_day_price_change += abs(($prices->at($n)->[$LAST] - $prices->at($n - 1)->[$LAST]));

    }
    
    # Calculate the VHF
    my $vhf = ($highest_close - $lowest_close) / $sum_of_one_day_price_change;
 
    # Return the results
    $indic->set($vhf_name, $i, $vhf);
}

1;
