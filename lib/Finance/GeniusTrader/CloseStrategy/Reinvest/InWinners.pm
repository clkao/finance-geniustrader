package Finance::GeniusTrader::CloseStrategy::Reinvest::InWinners;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::CloseStrategy;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::CloseStrategy);
@NAMES = ("ReinvestShortGain[#1]");
@DEFAULT_ARGS = (15);

=head1 Finance::GeniusTrader::CloseStrategy::Reinvest::InWinners

This Position Manager will reinvest money in winning trades every time they meet a new target. This strategy is based on the famous "Let your profits run and cut your losses" while thinking about trend following systems where it is very profitable to bet more when we catched a "big one" !

=cut

sub initialize {
    my ($self) = @_;
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'long_factor'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    $position->set_attribute("ReinvestInWinners::LongLimit", $position->open_price * $self->{'long_factor'});

    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'short_factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    $position->set_attribute("ReinvestInWinners::ShortLimit", $position->open_price * $self->{'short_factor'});

    return;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'long_factor'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    if ($position->has_attribute("ReinvestInWinners::LongLimit"))
    {
        my $limit = $position->attribute("ReinvestInWinners::LongLimit");
        my $price = $calc->prices->at($i)->[$LAST];
 
        if ($price > $limit)
        {
 
            # Increase the position size every time we meet a new target
            my $order = $pf_manager->buy_market_price($calc, $sys_manager->get_name);
	    $pf_manager->decide_quantity($order, $i, $calc);
	    if ($order->quantity > 0) {
		$pf_manager->submit_order_in_position($position, $order, $i, $calc);
	    }

            my $new_limit = $limit * $self->{'long_factor'};
	    $position->set_attribute("ReinvestInWinners::LongLimit", $new_limit);
        }
    }
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'short_factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    if ($position->has_attribute("ReinvestInWinners::ShortLimit"))
    {
	my $limit = $position->attribute("ReinvestInWinners::ShortLimit");
	my $price = $calc->prices->at($i)->[$LAST];
	
	if ($price < $limit)
	{
	    
	    # Increase the position size every time we meet a new target
	    my $order = $pf_manager->sell_market_price($calc, $sys_manager->get_name);
	    $pf_manager->decide_quantity($order, $i, $calc);
	    if ($order->quantity > 0) {
		$pf_manager->submit_order_in_position($position, $order, $i, $calc);
	    }
	    
	    my $new_limit = $limit * $self->{'short_factor'};
	    $position->set_attribute("ReinvestInWinners::ShortLimit", $new_limit);
	}
    }
    return;
}

1;
