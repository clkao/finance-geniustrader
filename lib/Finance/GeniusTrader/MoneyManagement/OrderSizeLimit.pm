package GT::MoneyManagement::OrderSizeLimit;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Prices;

@NAMES = ("OrderSizeLimit[#1]");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::OrderSizeLimit

=head2 Overview

This money management rule will keep an eye to the size of each order to
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
    my $maximum_shares = 0;

    # Initialization of portfolio value
    my $cash = $portfolio->current_cash;
    my $positions = $portfolio->current_evaluation;
    my $upcoming_gains_or_losses = $portfolio->current_marged_gains;
    my $portfolio_value = $cash + $positions + $upcoming_gains_or_losses;
 
    if (defined($order->{'quantity'})) {

	# Determine the maximum number of shares to trade
	if ($order->{'price'}) {
	   $maximum_shares = int($portfolio_value * $size_limit / $order->{'price'});
	} else {
	    $maximum_shares = int($portfolio_value * $size_limit / $calc->prices->at($i)->[$LAST]);
	}

	# Limit other money management's eager to bet too much !
	if ($order->{'quantity'} > $maximum_shares) {
	    return $maximum_shares;
	} else {
	    return $order->{'quantity'};
	}
    }
}

1;
