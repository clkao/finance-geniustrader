package GT::CloseStrategy::ChannelBreakout;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::CloseStrategy;
use GT::Eval;
use GT::Tools qw(:generic);

@ISA = qw(GT::CloseStrategy);
@NAMES = ("ChannelBreakout[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

GT::CloseStrategy::ChannelBreakout

=head1 DESCRIPTION

This Channel Breakout exit strategy close a position once the lower level
has been triggered for a long position, as well as the upper level for a
short position.

=cut

sub initialize {
    my ($self) = @_;

    $self->add_arg_dependency(1, 1);
    $self->add_arg_dependency(2, 1);
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return 0 if (! $self->check_dependencies($calc, $i));

    my $price = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $order = $pf_manager->sell_conditional($calc, $sys_manager->get_name, $price);
    $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    $position->set_no_intent_to_close;
    
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return 0 if (! $self->check_dependencies($calc, $i));

    my $price = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $order = $pf_manager->buy_conditional($calc, $sys_manager->get_name, $price);
    $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    $position->set_no_intent_to_close;
   
    return;
}

1;
