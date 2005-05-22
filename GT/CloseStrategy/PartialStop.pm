package GT::CloseStrategy::PartialStop;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::CloseStrategy;

@ISA = qw(GT::CloseStrategy);
@NAMES = ("PartialStop[#1, #2]");
@DEFAULT_ARGS = (5, 0.5);

=head1 GT::CloseStrategy::PartialStop

This strategy partialy closes the position once the prices have crossed a
limit called stop. This stop is defined as a percentage from the initial
price. By default, it's defined as - 5 %. The ratio of the position is
parameterized. By default it's half the initial position (0.5).

=cut

sub initialize {
    my ($self) = @_;
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'long_factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    my $ratio = $self->{'args'}->get_arg_values($calc, $i, 2);

    if (($ratio > 0) and ($ratio <= 1)) {
	my $order = $pf_manager->sell_conditional($calc,
	$position->source,
	$position->open_price * $self->{'long_factor'});
	$order->set_not_discardable;
	$pf_manager->set_order_partial($order, $ratio, $position);
	$pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }

    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'short_factor'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    my $ratio = $self->{'args'}->get_arg_values($calc, $i, 2);

    if (($ratio > 0) and ($ratio <= 1)) {
	my $order = $pf_manager->buy_conditional($calc,
	$position->source,
	$position->open_price * $self->{'short_factor'});
	$order->set_not_discardable;
	$pf_manager->set_order_partial($order, $ratio, $position);
	$pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }

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

