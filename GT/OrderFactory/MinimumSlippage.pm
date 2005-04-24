package GT::OrderFactory::MinimumSlippage;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::OrderFactory;
use Carp::Datum;

@ISA = qw(GT::OrderFactory);
@NAMES = ("MinimumSlippage");
@DEFAULT_ARGS = ();

=head1 NAME

GT::OrderFactory::MinimumSlippage

=head1 DESCRIPTION

In a Minimum Slippage test, we rig the software so that buy orders always
catch the minimum possible slippage : all buys occurs at the Low of the
day, and similarly all sells occurs at the High of the day.

=cut

sub create_buy_order {
    DFEATURE my $f;
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return DVAL $pf_manager->virtual_buy_at_low($calc, $sys_manager->get_name);
}

sub create_sell_order {
    DFEATURE my $f;
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return DVAL $pf_manager->virtual_sell_at_high($calc, $sys_manager->get_name);
}

1;
