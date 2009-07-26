package GT::CloseStrategy::Reinvest::ShortGain;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::CloseStrategy;
use GT::Prices;

@ISA = qw(GT::CloseStrategy);
@NAMES = ("ReinvestShortGain[#1]");
@DEFAULT_ARGS = (15);

=head1 GT::CloseStrategy::Reinvest::ShortGain

In a long position the gains are "automatically" reinvested since the
initial sum and the gains are on the market. With a short position this
is no more true. 

This CloseStrategy tries to defeat this by reinvesting the gains each time
a certain amount of gain has been made since last time the position was
augmented.

Use this CloseStrategy at the end of the "system chain" so that a position
is not augmented if it's planned to be closed.

=cut

sub initialize {
    my ($self) = @_;
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    $position->set_attribute("ReinvestShortGain::Limit",
			     $position->open_price * $self->{'factor'});
    $position->set_attribute("ReinvestShortGain::PreviousGain", 0);

    return;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    $self->{'factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    if ($position->has_attribute("ReinvestShortGain::Limit"))
    {
	my $limit = $position->attribute("ReinvestShortGain::Limit");
	my $prevgain = $position->attribute("ReinvestShortGain::PreviousGain");
	my $stats = $position->stats($pf_manager->portfolio);
	my $price = $calc->prices->at($i)->[$LAST];
	if ($price < $limit)
	{
	    # Augment the position according to the gains accumulated
	    # since the last time
	    my $gains = $stats->{'sold'} - $stats->{'bought'} -
			$stats->{'cost'} - $position->quantity * $price;
	    my $realgains = $gains - $prevgain;
	    if ($realgains > $price)
	    {
		my $quantity = int($realgains / $price);
		my $order = $pf_manager->sell_market_price($calc,
						    $sys_manager->get_name);
		$order->set_quantity($quantity);
		$pf_manager->submit_order_in_position($position, $order,
						      $i, $calc);
	    }
	    my $newlimit = $limit * $self->{'factor'};
	    $position->set_attribute("ReinvestShortGain::Limit", $newlimit);
	    $position->set_attribute("ReinvestShortGain::PreviousGain", $gains);
	}
    }
    return;
}

