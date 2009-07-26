package Finance::GeniusTrader::SystemManager;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(%OBJECT_REPOSITORY);

#ALL#  use Log::Log4perl qw(:easy);
use Finance::GeniusTrader::Eval;

=head1 NAME

Finance::GeniusTrader::SystemManager - Manages trading systems

=head1 DESCRIPTION

A SystemManager is an entity interacting between a PortfolioManager, a
Trading System (signals), TradeFilters, OrderFactory and CloseStrategy.

Filters can be applied to accept/refuse trades proposed by the trading
system.

A system manager is not completely defined until all desired objects have
been "linked" to it using all the add_* and set_* functions.  When all
those calls have been made, you should call B<finalize> to let the manager
know that you've finished setting it up. After that, the system manager
can be identified with an unique (and quite long) name.

Later you'll be able to setup the same system manager by using
setup_from_name($name).

=over

=item C<< my $sm = Finance::GeniusTrader::SystemManager->new($system) >>

Create a new system manager used to control a trading system.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $system = shift;

    my $self = { "filters" => [], "position_managers" => [] };
    
    bless $self, $class;
    
    if (defined($system)) {
	$self->set_portfolio($system);
    }

    return $self; 
}

=item C<< $sm->set_system($system) >>

Define the system that is managed.

=cut
sub set_system {
    my ($self, $system) = @_;

    #WAR#  WARN  "system is defined" if ( defined($system));
    
    $self->{"system"} = $system;
    return;
}

=item C<< $sm->system() >>

Return the system managed by this manager.

=cut
sub system {
    my ($self) = @_;
    return $self->{'system'};
}

=item C<< $manager->add_trade_filter() >>

=item C<< $manager->delete_all_trade_filter() >>

Use a trade filter and remove all trade filters currently used.

=cut
sub add_trade_filter {
    my ($self, $filter) = @_;

    push @{$self->{'filters'}}, $filter;
    
    return;
}
sub delete_all_trade_filter {
    my ($self) = @_;

    $self->{'filters'} = [];

    return;
}

=item C<< $self->accept_trade($order, $i, $calc, $pf_manager) >>

Apply all the trade filters to the proposed tarde and return
the result (accepted or not).

=cut
sub accept_trade {
    my ($self, $order, $i, $calc, $pf_manager) = @_;

    foreach (@{$self->{'filters'}})
    {
	if (! $_->accept_trade($order, $i, $calc, $pf_manager->portfolio))
	{
	    return 0;
	}
    }
    return 1;
}

=item C<< $self->send_buy_order($calc, $i, $pf_manager) >>

=item C<< $self->send_sell_order($calc, $i, $pf_manager) >>

Those functions are called by the systems to launch an order. The
SystemManager delegates this to an Order object. It will
use the Order object given by set_default_order() or it will
fallback to the order suggested by the system.

=cut
sub get_buy_order {
    my ($self, $calc, $i, $pf_manager) = @_;
    
    my $order;
    if (defined($self->{'order_factory'}))
    {
	$order = $self->{'order_factory'}->create_buy_order($calc, $i, 
				$self, $pf_manager);
    } else {
	$order = $self->{'system'}->default_order_factory->create_buy_order(
				$calc, $i, $self, $pf_manager);
    }
    return $order;
}

sub get_sell_order {
    my ($self, $calc, $i, $pf_manager) = @_;
    
    my $order;
    if (defined($self->{'order_factory'}))
    {
	$order = $self->{'order_factory'}->create_sell_order($calc, $i, 
				$self, $pf_manager);
    } else {
	$order = $self->{'system'}->default_order_factory->create_sell_order(
				$calc, $i, $self, $pf_manager);
    }
    return $order;
}

=item C<< $self->set_order_factory($order_factory) >>

Defines which OrderFactory object will be used to send the orders.

=cut
sub set_order_factory {
    my ($self, $os) = @_;
    $self->{'order_factory'} = $os;
}

=item C<< $self->add_position_manager($close_strategy) >>

=item C<< $self->delete_all_position_manager() >>


Add a position manager to the chain of position manager. A position
manager is better known as "CloseStragegy".

=cut
sub add_position_manager {
    my ($self, $cs) = @_;
    #WAR#  WARN  "Parameter must be a close strategy object" if ( ref($cs) =~ /Finance::GeniusTrader::CloseStrategy/);
    push @{$self->{'position_managers'}}, $cs;
    return;
}
sub delete_all_position_manager {
    my ($self) = @_;
    $self->{'position_managers'} = [];
    return;
}
sub default_position_manager {
    my ($self, $cs) = @_;
    if (! scalar(@{$self->{'position_managers'}}))
    {
	push @{$self->{'position_managers'}}, $cs;
    }
    return;
}

=item C<< $sm->manage_position($calc, $i, $position, $pf_manager) >>

Manages a open position with the current system.

=cut
sub manage_position {
    my ($self, $calc, $i, $position, $pf_manager) = @_;
    
    #WAR#  WARN  "position is defined" if ( defined($position));
    #WAR#  WARN  "position quantity is positive" if ( $position->quantity > 0);

    return if ($position->code() ne $calc->code());

    foreach my $cs (@{$self->{'position_managers'}})
    {
 	#ERR#  ERROR  "$_ should be a CloseStrategy object" if ( ref($cs) =~ /Finance::GeniusTrader::CloseStrategy/);
	if ($position->is_long) {
	    $cs->manage_long_position($calc, $i, $position, $pf_manager, $self);
	} else {
	    $cs->manage_short_position($calc, $i, $position, $pf_manager, $self);
	}
	# Stop the close strategy chain if the last strategy
	# decided to close the position
	last if ($position->being_closed);
    }
    return;
}

=item C<< $sm->position_opened($calc, $i, $position, $pf_manager) >>

Has to be called once a position has been opened and wants to be
managed by this system manager.

=cut
sub position_opened {
    my ($self, $calc, $i, $position, $pf_manager) = @_;
    
    #WAR#  WARN  "position is defined" if ( defined($position));
    #WAR#  WARN  "position quantity is positive" if ( $position->quantity > 0);

    foreach my $cs (@{$self->{'position_managers'}})
    {
	if ($position->is_long) {
	    $cs->long_position_opened($calc, $i, $position, $pf_manager, $self);
	} else {
	    $cs->short_position_opened($calc, $i, $position, $pf_manager, $self);
	}
    }
    return;
}

=item C<< $sm->get_indicative_stop($calc, $i, $order, $pf_manager) >>

Get an indicative stop level for the position that will be opened by
this order.

=cut
sub get_indicative_stop {
    my ($self, $calc, $i, $order, $pf_manager) = @_;

    my $stop = 0;
    foreach my $cs (@{$self->{'position_managers'}})
    {
	my $newstop = $cs->get_indicative_stop($calc, $i, $order, $pf_manager, $self);
	next if ($newstop == 0);
	$stop = $newstop if ($stop == 0);
	if ($order->is_buy_order)
	{
	    $stop = $newstop if ($newstop > $stop);
	} else {
	    $stop = $newstop if ($newstop < $stop);
	}
    }
    return $stop;
}
   
=item C<< $sm->apply_system($calc, $i, $pf_manager) >>

This function will use the generated signals to pass the order. It
delegates this responsibility to the PortfolioManager.

=cut
sub apply_system {
    my ($self, $calc, $i, $pf_manager) = @_;

    if ($self->system->long_signal($calc, $i))
    {
        my $order = $self->get_buy_order($calc, $i, $pf_manager);
	if (ref($order)) # Stop if order is not created
	{
	    $order->set_indicative_stop(
		$self->get_indicative_stop($calc, $i, $order, $pf_manager));
	    if ($self->accept_trade($order, $i, $calc, $pf_manager))
	    {
		$pf_manager->submit_order($order, $i ,$calc);
	    }
	}
    }
    if ($self->system->short_signal($calc, $i))
    {
        my $order = $self->get_sell_order($calc, $i, $pf_manager);
	if (ref($order)) # Stop if order is not created
	{
	    $order->set_indicative_stop(
		$self->get_indicative_stop($calc, $i, $order, $pf_manager));
	    if ($self->accept_trade($order, $i, $calc, $pf_manager))
	    {
		$pf_manager->submit_order($order, $i ,$calc);
	    }
	}
    }
    return;
}


sub apply_system_parked {
    my ($self, $calc, $i, $pf_manager) = @_;

    if ($self->system->long_signal($calc, $i))
    {
        my $order = $self->get_buy_order($calc, $i, $pf_manager);
	if (ref($order)) # Stop if order is not created
	{
	    $order->set_indicative_stop(
		$self->get_indicative_stop($calc, $i, $order, $pf_manager));
	    if ($self->accept_trade($order, $i, $calc, $pf_manager))
	    {
		$pf_manager->park_order($order, $i ,$calc);
	    }
	}
    }
    if ($self->system->short_signal($calc, $i))
    {
        my $order = $self->get_sell_order($calc, $i, $pf_manager);
	if (ref($order)) # Stop if order is not created
	{
	    $order->set_indicative_stop(
		$self->get_indicative_stop($calc, $i, $order, $pf_manager));
	    if ($self->accept_trade($order, $i, $calc, $pf_manager))
	    {
		$pf_manager->park_order($order, $i ,$calc);
	    }
	}
    }
    return;
}

=item C<< $sm->precalculate_interval($calc, $i, $first, $last) >>

=cut
sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;
    
    $self->{'system'}->precalculate_interval($calc, $first, $last);

    foreach my $cs (@{$self->{'position_managers'}})
    {
	$cs->precalculate_interval($calc, $first, $last);
    }
    foreach my $filter (@{$self->{'filters'}})
    {
	$filter->precalculate_interval($calc, $first, $last);
    }
   
    return;
}

=item C<< $sm->finalize() >>

Finalize the setup of the manager. Calculate its name. You can get its
name afterward using $sm->get_name

=cut
sub finalize {
    my ($self) = @_;

    my $name = get_standard_name($self->{'system'});
    if (defined($self->{'order_factory'}))
    {
	$name .= "|" . get_standard_name($self->{'order_factory'});
    }
    foreach my $obj ( (@{$self->{'filters'}}, @{$self->{'position_managers'}}) )
    {
	$name .= "|" . get_standard_name($obj);
    }
    $self->{'name'} = $name;

    $OBJECT_REPOSITORY{$name} = $self;
    
    return $name;
}

=item C<< $sm->get_name() >>

Return the name of the system.

=cut
sub get_name {
    my ($self) = @_;
    #ERR#  ERROR  "name is defined" if ( defined($self->{'name'}));
    return $self->{'name'};
}

=item C<< $sm->setup_from_name($name) >>

Setup the system manager according to the name.

=cut
sub setup_from_name {
    my ($self, $name) = @_;

    # Separate the system from the rest
    my ($system_name, @addons) = map { s/^\s*//g; s/\s*$//g; $_ }
                                 (split (/\|/, $name));
    my ($type, @system_args) = split(/\s+/, $system_name);
    $self->{'system'} = create_standard_object($type, @system_args);
    
    # Add all trade filters/order sender/close strategies
    foreach (@addons)
    {
        my ($obj_name, @args) = split /\s+/;
        my $object = create_standard_object($obj_name, @args);

        if (ref($object) =~ /TradeFilters::/) {
            $self->add_trade_filter($object);
        } elsif (ref($object) =~ /OrderFactory::/) {
	    $self->set_order_factory($object);
        } elsif (ref($object) =~ /CloseStrategy::/) {
	    $self->add_position_manager($object);
	} elsif (ref($object) =~ /MoneyManagement::/) {
            #$manager->add_money_management_rule($object);
        } else {
            die "Unknown object type: $name\n";
        }
    }
    # Set the name
    $self->{'name'} = $name;

    return;
}

=item C<< $sm->set_alias_name($name) >>

=item C<< $sm->alias_name >>


=cut
sub set_alias_name {
    $_[0]->{'alias'} = $_[1];
}
sub alias_name { defined($_[0]->{'alias'}) && $_[0]->{'alias'} }

=item C<< my $sm = Finance::GeniusTrader::SystemManager::get_registered_object($name) >>

Returns the system manager corresponding to this name.

=cut
sub get_registered_object {
    my ($name) = @_;
    return $OBJECT_REPOSITORY{$name};
}

=pod

=back

=cut
1;
