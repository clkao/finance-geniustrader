package GT::CloseStrategy::CloseGain;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::CloseStrategy;

@ISA = qw(GT::CloseStrategy);
@NAMES = ("CloseGain[#1]");

=head1 GT::CloseStrategy::CloseGain

This strategy closes the position once the prices have crossed a
limit called target. This target is defined as a percentage from the initial
price. By default, it's defined as + 25 %. If you use it together with
PartialGain, this strategy will only close the remaining shares to be
sold/bought. Take care however to place the CloseGain strategy after
the PartialGain strategy.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [ 25 ] };

    $self->{'args'}->[0] = 25 if (! defined($self->{'args'}->[0]));

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;
    $self->{'long_factor'} = 1 + $self->{'args'}[0] / 100;
    $self->{'short_factor'} = 1 - $self->{'args'}[0] / 100;
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    # Check for other "target" orders
    my $quantity = $position->quantity;
    foreach ($position->list_pending_orders)
    {
	if ((! $_->discardable) && $_->is_sell_order && $_->is_type_limited)
	{
	    $quantity -= $_->quantity;
	}
    }

    my $order = $pf_manager->sell_limited_price($calc, $position->source,
			    $position->open_price * $self->{'long_factor'});
    $order->set_not_discardable;
    $order->set_quantity($quantity);
    $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    $position->set_no_intent_to_close;

    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    # Check for other "target" orders
    my $quantity = $position->quantity;
    foreach ($position->list_pending_orders)
    {
	if ((! $_->discardable) && $_->is_buy_order && $_->is_type_limited)
	{
	    $quantity -= $_->quantity;
	}
    }
    
    my $order = $pf_manager->buy_limited_price($calc, $position->source,
			$position->open_price * $self->{'short_factor'});
    $order->set_not_discardable;
    $order->set_quantity($quantity);
    $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    $position->set_no_intent_to_close;

    return;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
   
    return;
}

