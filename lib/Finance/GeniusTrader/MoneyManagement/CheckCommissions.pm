package Finance::GeniusTrader::MoneyManagement::CheckCommissions;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::MoneyManagement;
use Finance::GeniusTrader::Prices;

@NAMES = ("CheckCommissions[#1]");
@ISA = qw(Finance::GeniusTrader::MoneyManagement);

=head1 Finance::GeniusTrader::MoneyManagement::CheckCommissions

=head2 Overview

This money management rule will keep an eye to the size of each trade.
Trade only when commissions represents less than a fixed percentage of the
investment.

=head2 Parameters

By default, we will accept all trades where commissions represents less
than 1 % of the investment and reject others.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ 0.005 ] };

    $args->[0] = 0.005 if (! defined($args->[0]));
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $percentage = $self->{'args'}[0];
    my $commission = 0;
    my $investment = 0;

    if (defined($order->quantity)) {

	# This is a bit hackish
	# A fake order is created with an execution price so that
	# we can calculate an associated cost (that's only an evaluation)
	
	my $bidon = Finance::GeniusTrader::Portfolio::Order->new;
	%{$bidon} = %{$order};
	$bidon->set_price($calc->prices->at($i)->[$LAST]);
	$commission = $portfolio->get_order_cost($bidon);
	
	# Accept all trades where commissions represents less
	# than 1 % of the investment and reject others.
	
	if ($order->price) {
	    $investment = $order->quantity * $order->price;
	} else {
	    $investment = $order->quantity * $calc->prices->at($i)->[$LAST];
	}
	if ($commission <= ($investment * $percentage)) {
	    return $order->quantity;
	} else {
	    return 0;
	}
    }
}

1;
