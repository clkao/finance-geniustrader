package GT::OrderFactory::SignalClosingPrice;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::OrderFactory;
use Carp::Datum;

@ISA = qw(GT::OrderFactory);
@NAMES = ("SignalClosingPrice");
@DEFAULT_ARGS = ();

=head1 NAME

GT::OrderFactory::SignalClosingPrice

=head1 DESCRIPTION

This module will send virtual order at the closing price when a new signal
is given.

=cut

sub create_buy_order {
    DFEATURE my $f;
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return DVAL $pf_manager->virtual_buy_at_signal($calc, $sys_manager->get_name);
}

sub create_sell_order {
    DFEATURE my $f;
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return DVAL $pf_manager->virtual_sell_at_signal($calc, $sys_manager->get_name);
}

1;
