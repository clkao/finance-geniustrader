package GT::OrderFactory::MaximumSlippage;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::OrderFactory;

@ISA = qw(GT::OrderFactory);
@NAMES = ("MaximumSlippage");
@DEFAULT_ARGS = ();

=head1 NAME

GT::OrderFactory::MaximumSlippage

=head1 DESCRIPTION

In a Maximum Slippage test, we rig the software so that buy orders always
suffer the maximum possible slippage : all buys occurs at the High of the
day, and similarly all sells occurs at the Low of the day.

This idea came from author Fred Gehm; it's a torture test designed to see
whether a system is robust against slippage.

=cut

sub create_buy_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return $pf_manager->virtual_buy_at_high($calc, $sys_manager->get_name);
}

sub create_sell_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return $pf_manager->virtual_sell_at_low($calc, $sys_manager->get_name);
}

1;
