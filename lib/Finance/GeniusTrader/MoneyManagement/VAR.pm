package Finance::GeniusTrader::MoneyManagement::VAR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::MoneyManagement;
use Finance::GeniusTrader::Indicators::StandardDeviation;
use Finance::GeniusTrader::Prices;

@NAMES = ("VAR[#1,#2]");
@ISA = qw(Finance::GeniusTrader::MoneyManagement);

=head1 Finance::GeniusTrader::MoneyManagement::VAR

=head2 Overview

This method uses market volatility and the concept of value at risk (VAR)
to help determine meaningful stop-loss prices and position limits for
trading securities.

=head2 References

"Value At Risk And Technical Analysis" by Luis Ballesca-Loyo
Technical Analysis of Stocks and Commodities - August 1999

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [10,2] };

    $args->[0] = 10 if (! defined($args->[0]));
    $args->[1] = 2 if (! defined($args->[1]));
 
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub initialize {
    my $self = shift;

    $self->{'sd'} = Finance::GeniusTrader::Indicators::StandardDeviation->new([ $self->{'args'}[0] ]);

    $self->add_indicator_dependency($self->{'sd'}, 1);
    $self->add_prices_dependency($self->{'args'}[0]);
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $prices = $calc->prices;
    my $period = $prices->count();
    my $indic = $calc->indicators;
    my $sd = $self->{'sd'};
    my $sd_name = $sd->get_name;
    my $maximum_percentage_of_portfolio_to_lose_per_trade = $self->{'args'}[1];
    my $sum = 0;
    
    return if (! $self->check_dependencies($calc, $i));
    
    for (my $j = 1; $j < $i; $j++) {

	# Sum ln of (Today's Close / Yesterday's Close)
	$sum += log($prices->at($j)->[$LAST] / $prices->at($j - 1)->[$LAST]);

    }

    my $mean = $sum / ($period - 1);
    my $standard_deviation = $indic->get($sd_name, $i);

    # X is the confidence coefficient depending on the degree of certainty
    # required. For 90 % certainty, X = 1.645, and for 95 % X = 1.96
    # We should be able to get the confidence level as an input value and
    # calculate automatically the X confidence coefficient, but let's try
    # your money management strategy without it with a 90 % confidence :
    my $X = 1.6448;
    
    # Upper Threshold = Today's Close * e^(mean + X * standard deviation)
    my $upper_threshold = $prices->at($i)->[$LAST] * exp($mean + $X * $standard_deviation / 100);
    
    # Lower Threshold = Today's Close * e^(mean + X * standard deviation)
    my $lower_threshold = $prices->at($i)->[$LAST] * exp($mean - $X * $standard_deviation / 100);

    # In a normal distribution, 90 % of the data and hence of the
    # probability lies in the range :
    my $upper_limit = $upper_threshold / $prices->at($i)->[$LAST] - 1;
    my $lower_limit = $lower_threshold / $prices->at($i)->[$LAST] - 1;
    
    # Initialization of portfolio value
    my $cash = $portfolio->current_cash;
    my $positions = $portfolio->current_evaluation;
    my $upcoming_gains_or_losses = $portfolio->current_marged_gains;
    my $portfolio_value = $cash + $positions + $upcoming_gains_or_losses;

    if ($portfolio_value > 0) {

	# Calculate the quantity to buy for a long trade
	if ($order->{'order'} eq "B") {

	    return int( - $portfolio_value * $maximum_percentage_of_portfolio_to_lose_per_trade / 100 / $lower_limit / $prices->at($i)->[$LAST] );
	}

	# Calculate the quantity to sell for a short trade
	if ($order->{'order'} eq "S") {
 
	    return int( $portfolio_value * $maximum_percentage_of_portfolio_to_lose_per_trade / 100 / $upper_limit / $prices->at($i)->[$LAST] );
	}
    } else {
	return 0;
    }
}

1;
