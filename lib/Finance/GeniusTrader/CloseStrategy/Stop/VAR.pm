package GT::CloseStrategy::Stop::VAR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::CloseStrategy;
use GT::Prices;
use GT::Indicators::StandardDeviation;

@ISA = qw(GT::CloseStrategy);
@NAMES = ("VAR[#1]");
@DEFAULT_ARGS = (10);

=head1 GT::CloseStrategy::Stop::VAR

=head2 Overview

This method uses market volatility and the concept of value at risk (VAR)
to help determine meaningful stop-loss prices and position limits for
trading securities.
 
=head2 References

"Value At Risk And Technical Analysis" by Luis Ballesca-Loyo
Technical Analysis of Stocks and Commodities - August 1999

=cut

sub initialize {
    my ($self) = @_;

    $self->{'sd'} = GT::Indicators::StandardDeviation->new([ $self->{'args'}->get_arg_names(1) ]);
    $self->add_indicator_dependency($self->{'sd'}, 1);
}

sub get_indicative_long_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;
    my $stop = 0;

    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    $self->remove_volatile_dependencies();
    $self->add_volatile_prices_dependency( $nb );

    return 0 if (! $self->check_dependencies($calc, $i));
    my $limit = $self->get_lower_limit($calc, $i);
    if ($order->price)
    {
	return $order->price * $limit;
    } else {
	return $calc->prices->at($i)->[$LAST] * $limit;
    }
}

sub get_indicative_short_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;
    my $stop = 0;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    $self->remove_volatile_dependencies();
    $self->add_volatile_prices_dependency( $nb );

    return 0 if (! $self->check_dependencies($calc, $i));
    my $limit = $self->get_upper_limit($calc, $i);
    if ($order->price)
    {
	return $order->price * $limit;
    } else {
	return $calc->prices->at($i)->[$LAST] * $limit;
    }
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    $self->remove_volatile_dependencies();
    $self->add_volatile_prices_dependency( $nb );
 
    return if (! $self->check_dependencies($calc, $i));
 
    my $lower_limit = $self->get_lower_limit($calc, $i);
    $position->set_stop($position->open_price * $lower_limit);
    
    return;
}

sub get_lower_limit {
    my ($self, $calc, $i) = @_;
    my $prices = $calc->prices;
    my $indic = $calc->indicators;
    my $sd_name = $self->{'sd'}->get_name;
    my $sum = 0;
    for (my $j = 1; $j < $i; $j++) {
 
        # Sum ln of (Today's Close / Yesterday's Close)
        $sum += log($prices->at($j)->[$LAST] / $prices->at($j - 1)->[$LAST]);
    }
 
    my $mean = $sum / ($i - 1);
    my $standard_deviation = $indic->get($sd_name, $i);

    # X is the confidence coefficient depending on the degree of certainty
    # required. For 90 % certainty, X = 1.645, and for 95 % X = 1.96
    my $X = 1.6448;
 
    # Lower Threshold = Today's Close * e^(mean + X * standard deviation)
    my $lower_threshold = $prices->at($i)->[$LAST] * exp($mean - $X * $standard_deviation / 100);
 
    # In a normal distribution, 95 % of the data will be above :
    my $lower_limit = $lower_threshold / $prices->at($i)->[$LAST];
    return $lower_limit;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
 
    return if (! $self->check_dependencies($calc, $i));
 
    my $upper_limit = $self->get_upper_limit($calc, $i);
    $position->set_stop($position->open_price * $upper_limit);

    return;
}

sub get_upper_limit {
    my ($self, $calc, $i) = @_;
    my $prices = $calc->prices;
    my $indic = $calc->indicators;
    my $sd_name = $self->{'sd'}->get_name;
    my $sum = 0;
    for (my $j = 1; $j < $i; $j++) {
 
        # Sum ln of (Today's Close / Yesterday's Close)
        $sum += log($prices->at($j)->[$LAST] / $prices->at($j - 1)->[$LAST]);
    }
 
    my $mean = $sum / ($i - 1);
    my $standard_deviation = $indic->get($sd_name, $i);

    # X is the confidence coefficient depending on the degree of certainty
    # required. For 90 % certainty, X = 1.645, and for 95 % X = 1.96
    my $X = 1.6448;
 
    # Lower Threshold = Today's Close * e^(mean + X * standard deviation)
    my $upper_threshold = $prices->at($i)->[$LAST] * exp($mean + $X * $standard_deviation / 100);
 
    # In a normal distribution, 95 % of the data will be above :
    my $upper_limit = $upper_threshold / $prices->at($i)->[$LAST];
    return $upper_limit;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $ps_manager, $sys_manager) = @_;
    
    return;
}

