package Finance::GeniusTrader::CloseStrategy::Conditional::TradeFilter;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::CloseStrategy;
use Finance::GeniusTrader::Eval;

@ISA = qw(Finance::GeniusTrader::CloseStrategy);
@NAMES = ("ConditionalTF[#*]");

=head1 Finance::GeniusTrader::CloseStrategy::OppositeSignal

This strategy closes the position once the opposite signal has been emitted
by the system. It will will close a long position on a sell signal and
close a short position on a buy signal.

=head2 Arguments

The arguments taken by this object are special. The first argument is
the name of a TradeFilter to use as the condition. It may be followed
by argument to give to the TradeFilter at creation time. After that,
there's the name of the real CloseStrategy to apply. This strategy will
only be applied if the trade filter accepts a fake "close order".

Examples or arguments :

...->new("TF:AroonTrend", "CS:Stop:SAR");
...->new("TF:FollowTrend", 15, "CS:Stop:SAR", 0.05, 0.02, 0.02);

The system detects the end of the arguments of the TradeFilter once it
detects "CS:" or "CloseStrategy:" at the beginning of the next argument.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    # Complicated hack to build the other objects according to the args
    my (@tf, @cs);
    push @tf, shift @{$args};
    my $elt;
    while ($elt = shift @{$args})
    {
	if ($elt =~ /^(CloseStrategy:|CS:)/)
	{
	    push @cs, $elt;
	    last;
	}
	push @tf, $elt;
    }
    push @cs, @{$args};
    
    my $tf_obj = create_standard_object(@tf);
    my $cs_obj = create_standard_object(@cs);
    @tf = split /\s+/, get_standard_name($tf_obj);
    @cs = split /\s+/, get_standard_name($cs_obj);

    my $self = { "args" => [ @tf, @cs ],
		 "tf" => $tf_obj, "cs" => $cs_obj };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    my $order = $pf_manager->sell_market_price($calc, $sys_manager->get_name);
    $order->set_quantity($position->quantity);
    if ($self->{'tf'}->accept_trade($order, $i, $calc, $pf_manager->portfolio))
    {
	$self->{'cs'}->long_position_opened($calc, $i, $position,
			    $pf_manager, $sys_manager);
    }

    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    my $order = $pf_manager->sell_market_price($calc, $sys_manager->get_name);
    $order->set_quantity($position->quantity);
    if ($self->{'tf'}->accept_trade($order, $i, $calc, $pf_manager->portfolio))
    {
	$self->{'cs'}->short_position_opened($calc, $i, $position,
			    $pf_manager, $sys_manager);
    }

    return;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    my $order = $pf_manager->sell_market_price($calc, $sys_manager->get_name);
    $order->set_quantity($position->quantity);
    if ($self->{'tf'}->accept_trade($order, $i, $calc, $pf_manager->portfolio))
    {
	$self->{'cs'}->manage_long_position($calc, $i, $position,
			    $pf_manager, $sys_manager);
    }

    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    my $order = $pf_manager->buy_market_price($calc, $sys_manager->get_name);
    $order->set_quantity($position->quantity);
    if ($self->{'tf'}->accept_trade($order, $i, $calc, $pf_manager->portfolio))
    {
	$self->{'cs'}->manage_short_position($calc, $i, $position,
			    $pf_manager, $sys_manager);
    }

    return;
}

