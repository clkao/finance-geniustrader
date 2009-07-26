package Finance::GeniusTrader::Indicators::GAPO;

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
@NAMES = ("GAPO[#*]");
@DEFAULT_ARGS = (5, "{I:Prices LOW}", "{I:Prices HIGH}");

=head1 Finance::GeniusTrader::Indicators::GAPO

=head2 Overview

The Gopalakarishnan Range Index (GAPO) characterizes the price behavior of markets. Although GAPO doesn't generate buy or sell signals, it does help identify the random behavior of price activity. A higher value indicates a more erratic market; a lower value indicates consistent price movement.

=head2 Calculation

GAPO = (Log(Highest High (n) - Lowest Low (n))) / Log (n)

=head2 Parameters

The standard GAPO index works with a five-day parameter : n = 5

=head2 Example

Finance::GeniusTrader::Indicators::GAPO->new()
Finance::GeniusTrader::Indicators::GAPO->new([6])

=head2 Advice/Idea

I think that the best way to use the results of this indicator is to look after the average or the moving average of the results, in order to have smooth data.

=cut
sub initialize {
    my $self = shift;

    $self->{'min'} = Finance::GeniusTrader::Indicators::Generic::MinInPeriod->new([ $self->{'args'}->get_arg_names(1), $self->{'args'}->get_arg_names(2) ]);
    $self->{'max'} = Finance::GeniusTrader::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_names(1), $self->{'args'}->get_arg_names(3) ]);

    $self->add_indicator_dependency($self->{'min'}, 1);
    $self->add_indicator_dependency($self->{'max'}, 1);
    $self->add_prices_dependency($self->{'args'}->get_arg_names(1));
}

=head2 Finance::GeniusTrader::Indicators::GAPO::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $q = $calc->prices;
    my $period = $self->{'args'}->get_arg_names(1);
    my $min = $self->{'min'};
    my $max = $self->{'max'};
    my $min_name = $min->get_name;
    my $max_name = $max->get_name;
    my $gapo_name = $self->get_name(0);

    return if ($indic->is_available($gapo_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # Get MIN and MAX values
    my $min_value = $indic->get($min_name, $i);
    my $max_value = $indic->get($max_name, $i);

    # The price range is equal to the difference between the highest price and the lowest price.
    my $price_range = $max_value - $min_value;
    
    # The price range divided by the log of the period of observation results in the index value.
    my $gapo_value = log($price_range) / log($period);
    
    # Return the result
    $indic->set($gapo_name, $i, $gapo_value);

}

1;
