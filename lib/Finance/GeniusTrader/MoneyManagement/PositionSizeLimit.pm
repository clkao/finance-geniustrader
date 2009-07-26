package Finance::GeniusTrader::MoneyManagement::PositionSizeLimit;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::MoneyManagement;
use Finance::GeniusTrader::Prices;

@NAMES = ("PositionSizeLimit[#1]");
@ISA = qw(Finance::GeniusTrader::MoneyManagement);

=head1 Finance::GeniusTrader::MoneyManagement::PositionSizeLimit

=head2 Overview

This money management rule will keep an eye to the size of each position to
remain them below a fixed percentage of the portfolio value.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [100] };

    $args->[0] = 100 if (! defined($args->[0]));
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $size_limit = ($self->{'args'}[0] / 100);
    my $code = $order->code;
    my $source = $order->source;
    my $maximum_shares = 0;
    my $shares = 0;

    # Initialization of portfolio value
    my $cash = $portfolio->current_cash;
    my $positions = $portfolio->current_evaluation;
    my $upcoming_gains_or_losses = $portfolio->current_marged_gains;
    my $portfolio_value = $cash + $positions + $upcoming_gains_or_losses;
 
    if (defined($order->quantity)) {

	# Initialization of $position with the last available position
	my $open_quantity = 0;
	foreach my $position ($portfolio->get_position($code, $source))
	{
	    # Check the position exists
	    next if (! defined($position));
	    
	    # Don't count the position that is being closed
	    next if ($position->being_closed);
	    
	    # How much shares are on play
	    my $stats = $position->stats($portfolio);
	    if ($position->is_long)
	    {
		$open_quantity += $position->quantity;
	    } else {
		$open_quantity -= $position->quantity;
	    }

	    # Well there may be pending orders to grow/reduce the position
	    # but since they may not be executed (in particular orders
	    # for partial close which are in the "pending" state for
	    # numerous days) I don't count them.
	}
	
	# Calculate the maximum number of shares we are allowed to trade
	# either on short or on long position
	if ($order->price) {
	    $maximum_shares = int($portfolio_value * $size_limit 
				 / $order->price);
	} else {
	    $maximum_shares = int($portfolio_value * $size_limit 
				  / $calc->prices->at($i)->[$LAST]);
	}

	# Remove the quantity that is already open
	$maximum_shares -= abs($open_quantity);

	# Return the number of shares to trade
	if (($order->quantity > 0) && ($order->quantity < $maximum_shares))
	{
	    return $order->quantity;
	} elsif ($maximum_shares > 0) {
	    return $maximum_shares;
	} else {
	    return 0;
	}
    }
}

1;
