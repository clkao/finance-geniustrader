package Finance::GeniusTrader::Portfolio::Position;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
our @ISA = qw(Finance::GeniusTrader::Serializable);

#ALL# use Log::Log4perl qw(:easy);
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Serializable;

=head1 NAME

Finance::GeniusTrader::Portfolio::Position - An open position within a portfolio

=head1 DESCRIPTION

=head2 Internal structure

  {
    "long" => 1,	    # 1:Long 0:Short
    "code" => "13000",
    "quantity" => 100,
    "initial_quantity" => 100, # Quantity when position was opened
    "open_price" => 12.4,      # Price when position has been taken
    "close_price" => 13.2,     # Prices when position has been closed
    "source" => "Trend",       # Which trading system opened the position
    "open_date" => "2001-07-01",
    "close_date" => "2001-07-04",
    "stop" => 12	       # Stop is at 12
  }

=head2 Functions

=over

=item C<< $p = Finance::GeniusTrader::Portfolio::Position->new($code, $source, $date) >>

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($code, $source, $date) = @_;

    my $self = { "details" => [], "pending_orders" => [], "quantity" => 0,
		 "attributes" => {} };
    bless $self, $class;

    $self->set_code($code) if (defined($code));
    $self->set_source($source) if (defined($source));
    $self->set_open_date($date) if (defined($date));
    
    return $self;
}

=item C<< $p->set_long() >>

=item C<< $p->set_short() >>

=item C<< $p->is_long() >>

=item C<< $p->is_short() >>


=cut
sub set_long  { $_[0]->{'long'} = 1 }
sub set_short { $_[0]->{'long'} = 0 }
sub is_long   { $_[0]->{'long'} == 1 }
sub is_short  { $_[0]->{'long'} == 0 }

=item C<< $p->set_code($code) >>

=item C<< $p->code() >>


=cut
sub set_code {
    my ($self, $code) = @_;
    $self->{'code'} = $code;
}
sub code { $_[0]->{'code'} }

=item C<< $p->set_quantity($quantity) >>

=item C<< $p->quantity() >>

=item C<< $p->set_initial_quantity($quantity) >>

=item C<< $p->initial_quantity() >>


=cut
sub set_quantity {
    my ($self, $q) = @_;
    $self->{'quantity'} = $q;
}
sub quantity { $_[0]->{'quantity'} }
sub set_initial_quantity {
    my ($self, $q) = @_;
    $self->{'initial_quantity'} = $q;
}
sub initial_quantity { $_[0]->{'initial_quantity'} }

=item C<< $p->set_open_price($price) >>

=item C<< $p->open_price() >>

=item C<< $p->set_close_price($price) >>

=item C<< $p->close_price() >>

=cut
sub set_open_price {
    my ($self, $price) = @_;
    $self->{'open_price'} = $price;
}
sub set_close_price {
    my ($self, $price) = @_;
    $self->{'close_price'} = $price;
}
sub open_price  { $_[0]->{'open_price'} }
sub close_price { $_[0]->{'close_price'} }

=item C<< $p->set_source($source) >>

=item C<< $p->source() >>


=cut
sub set_source {
    my ($self, $source) = @_;
    $self->{'source'} = $source;
}
sub source { $_[0]->{'source'} }

=item C<< $p->set_open_date($date) >>

=item C<< $p->open_date() >>

=item C<< $p->set_close_date($date) >>

=item C<< $p->close_date() >>


=cut
sub set_open_date {
    my ($self, $date) = @_;
    $self->{'open_date'} = $date;
}
sub open_date { $_[0]->{'open_date'} }
sub set_close_date {
    my ($self, $date) = @_;
    $self->{'close_date'} = $date;
}
sub close_date { $_[0]->{'close_date'} }

=item C<< $p->set_id($id) >>

=item C<< $p->id() >>


=cut
sub set_id {
    my ($self, $id) = @_;
    $self->{'id'} = $id;
}
sub id { $_[0]->{'id'} }

=item C<< $p->set_stop($price) >>

=item C<< $p->update_stop($price) >>

=item C<< $p->force_stop($price) >>

=item C<< $p->stop() >>

set_stop and update_stop modifies the stop level but it won't let you
further the stop, you can only bring it nearer. If you want to further
the stop level use force_stop.

=cut
sub set_stop {
    my ($self, $price) = @_;
    if (! (defined($self->{'stop'}) && $self->{'stop'}))
    {
	$self->{'stop'} = $price;
	return;
    }
    if ($self->is_long) {
	if ($price > $self->{'stop'})
	{
	    $self->{'stop'} = $price;
	}
    } else {
	if ($price < $self->{'stop'})
	{
	    $self->{'stop'} = $price;
	}
    }
}
sub update_stop { set_stop(@_) }
sub force_stop {
    my ($self, $price) = @_;
    $self->{'stop'} = $price;
}
sub stop { $_[0]->{'stop'} }

=item C<< $p->set_attribute($key, [ $value ]); >>

=item C<< $p->has_attribute($key); >>

=item C<< $p->attribute($key); >>

=item C<< $p->delete_attribute($key); >>

A position can have "attributes" associated to keep track of its status
in various strategies. has_attribute returns only true if the attribute
exists (whatever its value is). attribute returns the attribute value if
it exists or undef otherwise.

=cut
sub set_attribute {
    my ($self, $key, $value) = @_;
    $value = 1 if (! defined($value));
    $self->{'attributes'}{$key} = $value;
}
sub has_attribute {
    my ($self, $key) = @_;
    return 1 if (exists $self->{'attributes'}{$key});
    return 0;
}
sub attribute {
    my ($self, $key) = @_;
    if (exists $self->{'attributes'}{$key})
    {
	return $self->{'attributes'}{$key};
    }
    return undef;
}
sub delete_attribute {
    my ($self, $key) = @_;
    delete $self->{'attributes'}{$key};
}

=item C<< $p->set_timeframe($timeframe) >>

=item C<< $p->timeframe() >>

Set and return the timeframe associated to this position.

=cut
sub set_timeframe { $_[0]->{'timeframe'} = $_[1] }
sub timeframe { $_[0]->{'timeframe'} }

=item C<< $p->set_marged() >>

=item C<< $p->set_not_marged() >>

=item C<< $p->is_marged() >>

A marged position is constitued of shares that have been "rented" (or
bought with rented cash).

=cut
sub set_marged     { $_[0]->{'marged'} = 1 }
sub set_not_marged { $_[0]->{'marged'} = 0 }
sub is_marged      { defined($_[0]->{'marged'}) && $_[0]->{'marged'} }

=item C<< $p->apply_order($order, $price, $date) >>

Update the position with the corresponding order. The order has been executed at the given date
and at the given price.

=cut
sub apply_order {
    my ($self, $order, $price, $date) = @_;

    #WAR# WARN "order quantity is positive" unless ($order->quantity > 0);

    if (! defined($price)) {
	$price = $order->price();
    }

    #ERR# ERROR "applying an order without price" unless (defined($price));

    # Store the modification to the position
    my $history = Finance::GeniusTrader::Portfolio::Order->new;
    if ($order->is_buy_order) {
	$history->set_buy_order;
    } else {
	$history->set_sell_order;
    }
    $history->set_submission_date($date);
    $history->set_price($price);
    $history->set_quantity($order->quantity);
    $history->set_type($order->type);
    $history->set_timeframe($self->timeframe);
    
    push @{$self->{'details'}}, $history;

    # Update the position
    if ($self->quantity) {
	if ($self->is_long) {
	    if ($order->is_buy_order) {
		$self->{'quantity'} += $order->quantity;
	    } else {
		$self->{'quantity'} -= $order->quantity;
	    }
	} else {
	    if ($order->is_sell_order) {
		$self->{'quantity'} += $order->quantity;
	    } else {
		$self->{'quantity'} -= $order->quantity;
	    }
	}
    } else {
	$self->{'long'} = ($order->is_buy_order) ? 1 : 0;
	$self->set_quantity($order->quantity);
	$self->set_initial_quantity($order->quantity);
	$self->set_open_price($price);
	$self->set_open_date($date);
    }

    #ERR# ERROR "position quantity must stay above zero" unless ($self->quantity >= 0);

    # If position is closed, remove it of open_positions and add to
    # history, and clear the orders on that position
    if ($self->quantity == 0)
    {
	$self->set_close_date($date);
	$self->{'pending_orders'} = [];
    }
    
    return 1;
}

=item C<< $p->apply_pending_orders($calc, $i) >>


=cut
sub apply_pending_orders {
    my ($self, $calc, $i) = @_ ;
    
    # Try to apply stop defined as orders
    foreach (grep { $_->is_type_stop &&
		    (($self->is_long  && $_->is_sell_order) ||
		     ($self->is_short && $_->is_buy_order))
		  } ($self->list_pending_orders))
    {
	next if (! defined($_));

	my $price = $_->is_executed($calc, $i);
        if ($price)
        {
	    $self->apply_order($_, $price, $calc->prices->at($i)->[$DATE]);
            $self->delete_order($_);
        } else {
            if ($_->discardable) {
                $self->discard_order($_);
            } else {
                # Do not discard
            }
        }
    }
    
    # Try to apply the stop if there's something left to stop
    if (defined($self->stop) && $self->stop && $self->quantity)
    {
	my $order = Finance::GeniusTrader::Portfolio::Order->new;
	if ($self->is_long)
	{
	    $order->set_sell_order;
	} else {
	    $order->set_buy_order;
	}
	$order->set_type_stop;
	$order->set_price($self->stop);
	$order->set_quantity($self->quantity);

	my $apply_stop = 1;
	
	if ($self->open_date eq $calc->prices->at($i)->[$DATE])
	{
	    # First day, we can't always be sure how the stop has
	    # been managed

	    # We're sure that the stop has been executed if the close
	    # price has broken the stop level (because the position has
	    # been opened before...)
	    if ($self->is_long)
	    {
		if ($self->stop < $calc->prices->at($i)->[$LAST])
		{
		    $apply_stop = 0;
		}
	    } else {
		if ($self->stop > $calc->prices->at($i)->[$LAST])
		{
		    $apply_stop = 0;
		}
	    }
	}
	
	if ($apply_stop && $order->is_executed($calc, $i))
	{
	    $self->apply_order($order, $self->stop, $calc->prices->at($i)->[$DATE]);
	    return;
	}
    }
    
    # Apply the other orders
    foreach ($self->list_pending_orders) 
    {
	next if (! defined($_));
	
	my $price;
	if ($price = $_->is_executed($calc, $i)) 
	{
	    $self->apply_order($_, $price, $calc->prices->at($i)->[$DATE]);
	    $self->delete_order($_);
	} else {
	    if ($_->discardable) {
		$self->discard_order($_);
	    } else {
		# Do not discard
	    }
	}
    }
    return;
}

=item C<< $p->add_order($order) >>

Add a new pending order to the position.

=cut
sub add_order {
    my ($self, $order) = @_;

    $order->set_id(scalar @{$self->{'pending_orders'}});
    push @{$self->{'pending_orders'}}, $order;
    
    return $order->{'id'};
}

=item C<< $p->delete_order($order) >>


=cut
sub delete_order {
    my ($self, $order) = @_;

    $self->{'pending_orders'}[$order->id] = undef;
    return;
}

=item C<< $p->discard_order($order) >>


=cut
sub discard_order {
    delete_order(@_);
}

=item C<< $p->list_pending_orders() >>

Returns the list of pending orders on the position. Those orders have not
yet been executed.

=cut
sub list_pending_orders {
    my ($self) = @_;

    return grep { defined($_) } @{$self->{'pending_orders'}};
}

=item C<< $p->list_detailed_orders() >>

Returns the list of detailed orders on the position. Those orders
have already been executed.

=cut
sub list_detailed_orders {
    my ($self) = @_;

    return grep { defined($_) } @{$self->{'details'}};
}


=item C<< $p->is_open() >>

Returns true if the position is still open (ie if quantity != 0)

=cut
sub is_open {
    my ($self) = @_;

    my $bool = ($self->quantity > 0) ? 1 : 0;
    return $bool;
}

=item C<< $p->set_intent_to_close() >>

Mark the position as being in the process of being closed. This will
let the system detect new opportunities as soon as possible.

=cut
sub set_intent_to_close {
    my ($self) = @_;
    $self->{'intend_to_close'} = 1;
    return;
}

=item C<< $p->set_no_intent_to_close() >>

DeMark the position as being in the process of being closed. This will
let the system manage the position without knowing that some orders
have been placed to close the position (ie those orders may or may not
be executed).

=cut
sub set_no_intent_to_close {
    my ($self) = @_;
    $self->{'intend_to_close'} = 0;
    return;
}

=item C<< $p->being_closed() >>

Returns true if the position is in the process of beeing closed.

=cut
sub being_closed {
    my ($self) = @_;
    if (defined($self->{'intend_to_close'}) &&
	$self->{'intend_to_close'})
    {
	return 1;
    }
    return 0;
}

=item C<< $p->stats($portfolio, [ $quantity_factor ]) >>

Calculate some statistics about the position.

=cut
sub stats {
    my ($self, $portfolio, $quantity_factor) = @_;
    
    #WAR# WARN "first arg of position->stats must be a portfolio" unless (ref($portfolio) =~ /Finance::GeniusTrader::Portfolio/);
    
    if (! defined($quantity_factor))
    {
	$quantity_factor = 1;
    }
    
    my ($quantity_sold, $quantity_bought, $bought, $sold, $nb_sell_orders,
	$nb_buy_orders, $cost) = (0, 0, 0, 0, 0, 0, 0);
    foreach (@{$self->{'details'}})
    {
	next if (! defined($_));
	
	
	my $sum = $quantity_factor * $_->quantity * $_->price;
	if ($_->is_buy_order) {
	    $nb_buy_orders++;
	    $bought += $sum;
	    $quantity_bought += $quantity_factor * $_->quantity;
	} elsif ($_->is_sell_order) {
	    $nb_sell_orders++;
	    $sold += $sum;
	    $quantity_sold += $quantity_factor * $_->quantity;
	}
	$cost += $portfolio->get_order_cost($_);
    }
    
    return {
	"bought" => $bought,
	"sold"   => $sold,
	"quantity" => $quantity_bought,
	"quantity_bought" => $quantity_bought,
	"quantity_sold" => $quantity_sold,
	"nb_orders" => $nb_buy_orders + $nb_sell_orders,
	"nb_buy_orders" => $nb_buy_orders,
	"nb_sell_orders" => $nb_sell_orders,
	"cost" => $cost
    };
}

=pod

=back

=cut
1;
