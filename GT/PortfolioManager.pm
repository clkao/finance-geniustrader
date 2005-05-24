package GT::PortfolioManager;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

#ALL#  use Log::Log4perl qw(:easy);
use GT::Portfolio;
use GT::Prices;
use GT::SystemManager;
use GT::Eval;

=head1 NAME

GT::PortfolioManager - Manages a portfolio

=head1 DESCRIPTION

A PortfolioManager is an entity interacting between a Portfolio,
a Trading System, money management rules and trade filters.

When it comes to starting a new position (ie submitting an order
to start a position), the money management system comes in again to
decide how much to put on the trade. 

Filters can be applied to accept/refuse trades proposed by the 
various trading systems.

=over

=item C<< my $manager = GT::PortfolioManager->new($portfolio) >>

Create a new portfolio manager that implements a money management
strategy.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $portfolio = shift;

    my $self = { "moneymanagement" => [] };
    
    bless $self, $class;
    
    if (defined($portfolio)) {
	$self->set_portfolio($portfolio);
    }

    return $self; 
}

=item C<< $manager->set_portfolio($portfolio) >>

Change the portfolio managed.

=cut
sub set_portfolio {
    my ($self, $portfolio) = @_;

    #WAR#  WARN  "portfolio is defined" if ( defined($portfolio));
    
    $self->{"portfolio"} = $portfolio;

    return;
}

=item C<< $manager->portfolio() >>

Returns the managed portfolio.

=cut
sub portfolio {
    my ($self) = @_;
    return $self->{'portfolio'};
}

=item C<< $order = $manager->buy_market_price($calc, $source) >>

=item C<< $order = $manager->buy_limited_price($calc, $source, $price)  >>

=item C<< $order = $manager->buy_conditional($calc, $source, $price [, $price2]) >>

=item C<< $order = $manager->virtual_buy_at_open($calc, $source) >>

=item C<< $order = $manager->virtual_buy_at_high($calc, $source) >>

=item C<< $order = $manager->virtual_buy_at_low($calc, $source) >>

=item C<< $order = $manager->virtual_buy_at_close($calc, $source) >>

=item C<< $order = $manager->virtual_buy_at_signal($calc, $source) >>

=item C<< $order = $manager->sell_market_price($calc, $source) >>

=item C<< $order = $manager->sell_limited_price($calc, $source, $price)  >>

=item C<< $order = $manager->sell_conditional($calc, $source, $price [, $price2]) >>

=item C<< $order = $manager->virtual_sell_at_open($calc, $source) >>

=item C<< $order = $manager->virtual_sell_at_high($calc, $source) >>

=item C<< $order = $manager->virtual_sell_at_low($calc, $source) >>

=item C<< $order = $manager->virtual_sell_at_close($calc, $source) >>

=item C<< $order = $manager->virtual_sell_at_signal($calc, $source) >>

Those functions are used to create orders that may be modified
and submitted later.

=cut

# TODO 
# put an indicatory price to allow money management to decide of
# quantity

sub buy_market_price {
    my ($self, $calc, $source) = @_;

    my $order = GT::Portfolio::Order->new;
    $order->set_buy_order;
    $order->set_type_market_price;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub buy_limited_price {
    my ($self, $calc, $source, $price) = @_;

    my $order = GT::Portfolio::Order->new;
    $order->set_buy_order;
    $order->set_type_limited;
    $order->set_code($calc->code);
    $order->set_source($source);
    $order->set_price($price);
    return $order;
}

sub buy_conditional {
    my ($self, $calc, $source, $price, $price2) = @_;
    
    my $order = GT::Portfolio::Order->new;
    $order->set_buy_order;
    $order->set_code($calc->code);
    $order->set_source($source);
    $order->set_price($price);

    if (defined($price2)) {
	$order->set_type_stop_limited;
	$order->set_second_price($price2);
    } else {
	$order->set_type_stop;
    }
    return $order;
}

sub virtual_buy_at_open {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_buy_order;
    $order->set_type_theoric_at_open;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub virtual_buy_at_high {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_buy_order;
    $order->set_type_theoric_at_high;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub virtual_buy_at_low {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_buy_order;
    $order->set_type_theoric_at_low;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub virtual_buy_at_close {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_buy_order;
    $order->set_type_theoric_at_close;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub virtual_buy_at_signal {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_buy_order;
    $order->set_type_theoric_at_signal;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub sell_market_price {
    my ($self, $calc, $source) = @_;

    my $order = GT::Portfolio::Order->new;
    $order->set_sell_order;
    $order->set_type_market_price;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub sell_limited_price {
    my ($self, $calc, $source, $price) = @_;
    
    my $order = GT::Portfolio::Order->new;
    $order->set_sell_order;
    $order->set_type_limited;
    $order->set_code($calc->code);
    $order->set_source($source);
    $order->set_price($price);
    return $order;
}

sub sell_conditional {
    my ($self, $calc, $source, $price, $price2) = @_;
    
    my $order = GT::Portfolio::Order->new;
    $order->set_sell_order;
    $order->set_code($calc->code);
    $order->set_source($source);
    $order->set_price($price);

    if (defined($price2)) {
	$order->set_type_stop_limited;
	$order->set_second_price($price2);
    } else {
	$order->set_type_stop;
    }
    return $order;
}

sub virtual_sell_at_open {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_sell_order;
    $order->set_type_theoric_at_open;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub virtual_sell_at_high {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_sell_order;
    $order->set_type_theoric_at_high;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub virtual_sell_at_low {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_sell_order;
    $order->set_type_theoric_at_low;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub virtual_sell_at_close {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_sell_order;
    $order->set_type_theoric_at_close;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

sub virtual_sell_at_signal {
    my ($self, $calc, $source) = @_;
 
    my $order = GT::Portfolio::Order->new;
    $order->set_sell_order;
    $order->set_type_theoric_at_signal;
    $order->set_code($calc->code);
    $order->set_source($source);
    return $order;
}

=item C<< $manager->set_order_partial($order, $ratio) >>

When you want to close a position, you may want to not close it
fully. With this function, you indicate how much of the initial position
you want to close.

=cut
sub set_order_partial {
    my ($self, $order, $ratio, $position) = @_;

    #WAR#  WARN  "ratio is positive" if ( $ratio > 0);
    #WAR#  WARN  "order is defined" if ( defined($order));
    #WAR#  WARN  "position is defined" if ( defined($position));

    my $init_quant = defined($position->initial_quantity) ?
			$position->initial_quantity :
			$position->quantity;
    $order->{'quantity'} = int($init_quant * $ratio);

    #WAR#  WARN  "order quantity is positive" if ( $order->quantity > 0);
    
    return $order;
}

=item C<< $manager->discard_all_orders($calc, $source) >>

Discards all orders concerning this share and this source.

=cut
sub discard_all_orders {
    my ($self, $calc, $source) = @_;

    foreach (grep { $_->code eq $calc->code }
	     $self->{'portfolio'}->list_pending_orders($source))
    {
	$self->{'portfolio'}->discard_order($_->{'id'});
    }
    return;
}

=item C<< $manager->submit_order($order, $i, $calc) >>

=item C<< $manager->submit_order_in_position($position, $order, $i, $calc) >>

Submit the prepared order, either an order that will start a new position
or as an order that will modify an existing position.

=cut
sub submit_order {
    my ($self, $order, $i, $calc) = @_;

    #WAR#  WARN  "order is defined" if ( defined($order));
    #WAR#  WARN  "day number $i is valid" if ( $i >= 0);
    #WAR#  WARN  "calc is defined" if ( defined($calc));

    $order->set_timeframe($calc->current_timeframe);

    # Short positions only possible with marged positions
    $order->set_marged if ($order->is_sell_order);

    if (! defined($order->quantity)) {
	if (! $self->decide_quantity($order, $i, $calc))
	{
	    # Trade refused by money management
	    return 0;
	}
    }

    #WAR#  WARN  "order quantity is positive" if ( $order->quantity > 0);
    
    # TODO
    # Update other fields of the order like dates and so on
    $self->{'portfolio'}->add_order($order);
    return 1;
}

sub submit_order_in_position {
    my ($self, $position, $order, $i, $calc) = @_;

    #WAR#  WARN  "order is defined" if ( defined($order));
    #WAR#  WARN  "day number $i is valid" if ( $i >= 0);
    #WAR#  WARN  "calc is defined" if ( defined($calc));
    #WAR#  WARN  "position quantity is positive" if ( $position->quantity > 0);

    $order->set_timeframe($calc->current_timeframe);
    
    $order->set_marged if ($position->is_marged);
    
    if (! defined($order->quantity)) {
	$order->set_quantity($position->quantity);
    }

    #WAR#  WARN  "order quantity is positive" if ( $order->quantity > 0);
    
    # Mark the position as being closed
    if ($order->quantity == $position->quantity)
    {
	if ($position->is_long)
	{
	    if ($order->is_sell_order)
	    {
		$position->set_intent_to_close;
	    }
	} else {
	    if ($order->is_buy_order)
	    {
		$position->set_intent_to_close;
	    }
	}
    }

    # TODO
    # Update other fields of the order like dates and so on
    $position->add_order($order);
    return;
}


sub park_order {
    my ($self, $order, $i, $calc) = @_;

    #WAR# WARN "order is defined" unless (defined($order));
    #WAR# WARN "day number $i is valid" unless ($i >= 0);
    #WAR# WARN "calc is defined" unless (defined($calc));

    $order->set_timeframe($calc->current_timeframe);

    # Short positions only possible with marged positions
    $order->set_marged if ($order->is_sell_order);

    push @{$self->{'portfolio'}->{'parked-orders'}},
      [$order, $i, $calc ];

    return 1;
}

sub submit_parked_orders {
    my $self = shift;

    foreach my $p ( @{$self->{'portfolio'}->{'parked-orders'}} ) {
        my $order = $p->[0];
        my $i = $p->[1];
        my $calc = $p->[2];

#        print $i . " --> " . $calc->code() . "\n";

        if (! defined($order->quantity)) {
	    if (! $self->decide_quantity($order, $i, $calc) )
	    {
	        # Trade refused by money management
	        next;
	    } elsif (! defined($order->quantity)) {
	      next;
	    }
        }

        #WAR# warn "order quantity is positive " . $order->quantity if ($order->quantity > 0);
    
        # TODO
        # Update other fields of the order like dates and so on
        $self->{'portfolio'}->add_order($order);

    }

    @{$self->{'portfolio'}->{'parked-orders'}} = ();
}

sub delete_parked_orders {
    my $self = shift;
    @{$self->{'portfolio'}->{'parked-orders'}} = ();
}

=item C<< $manager->add_money_management_rule($mm_rule) >>

=item C<< $manager->delete_all_money_management_rule() >>

=item C<< $manager->default_money_management_rule($mm_rule) >>

Use a money management rule and remove all money management
rules currently used.

=cut
sub add_money_management_rule {
    my ($self, $mmrule) = @_;

    push @{$self->{'moneymanagement'}}, $mmrule;

    return;
}
sub delete_all_money_management_rule {
    my ($self) = @_;

    $self->{'moneymanagement'} = [];

    return;
}
sub default_money_management_rule {
    my ($self, $mmrule) = @_;

    if (! scalar(@{$self->{'moneymanagement'}}))
    {
	push @{$self->{'moneymanagement'}}, $mmrule;
    }

    return;
}

=item C<< $manager->decide_quantity($order, $i, $calc) >>

Apply the various money management rules and decide the size
of the position.

=cut
sub decide_quantity {
    my ($self, $order, $i, $calc) = @_;

    foreach my $mm (@{$self->{'moneymanagement'}})
    {
	my $nq = $mm->manage_quantity($order, $i, $calc,	$self->{'portfolio'});
	$order->set_quantity($nq);
    }
    return $order->quantity;
}

=item C<< $manager->finalize() >>

Finalize the setup of the manager. Calculate its name. You can get its
name afterward using $manager->get_name.

=cut
sub finalize {
    my ($self) = @_;

    my $name = join "|", map { get_standard_name($_) }
			     @{$self->{'moneymanagement'}};
    $self->{'name'} = $name;
    
    return $name;
}

=item C<< $manager->get_name() >>

Return the name of the system.

=cut
sub get_name {
    my ($self) = @_;
    #ERR#  ERROR  "name is defined" if ( defined($self->{'name'}));
    return $self->{'name'};
}

=item C<< $manager->setup_from_name($name) >>

Setup the portfolio manager according to the name, it will create the
corresponding money management rules.

=cut
sub setup_from_name {
    my ($self, $name) = @_;

    # Add all money management rules
    foreach (split (/\|/, $name))
    {
	s/^\s+//g; s/\s+$//g;
        my ($obj_name, @args) = split /\s+/;
        my $object = create_standard_object($obj_name, @args);

        if (ref($object) =~ /MoneyManagement::/) {
            $self->add_money_management_rule($object);
        }
    }
    return;
}

=pod

=back

=cut
1;
