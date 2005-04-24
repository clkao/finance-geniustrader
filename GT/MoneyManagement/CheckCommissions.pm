package GT::MoneyManagement::CheckCommissions;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Prices;
use Carp::Datum;

@NAMES = ("CheckCommissions[#1]");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::CheckCommissions

=head2 Overview

This money management rule will keep an eye to the size of each trade.
Trade only when commissions represents less than a fixed percentage of the
investment.

=head2 Parameters

By default, we will accept all trades where commissions represents less
than 1 % of the investment and reject others.

=cut

sub new {
    DFEATURE my $f, "new MoneyManagement";
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ 0.005 ] };

    $args->[0] = 0.005 if (! defined($args->[0]));
    
    return DVAL manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    DFEATURE my $f;
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $percentage = $self->{'args'}[0];
    my $commission = 0;
    my $investment = 0;

    if (defined($order->quantity)) {

	# This is a bit hackish
	# A fake order is created with an execution price so that
	# we can calculate an associated cost (that's only an evaluation)
	
	my $bidon = GT::Portfolio::Order->new;
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
	    return DVAL $order->quantity;
	} else {
	    return DVAL 0;
	}
    }
}

1;
