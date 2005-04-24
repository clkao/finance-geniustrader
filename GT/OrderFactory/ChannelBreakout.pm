package GT::OrderFactory::ChannelBreakout;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::OrderFactory;
use Carp::Datum;
use GT::Eval;
use GT::Indicators qw($GET_LAST);
use GT::Tools qw(:generic);

@ISA = qw(GT::OrderFactory);
@NAMES = ("ChannelBreakout[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

GT::OrderFactory::ChannelBreakout

=head1 DESCRIPTION

This module is able to set up a generic channel breakout strategy based on
two generic limited price order, above and below current prices. Both
levels will be defined with an indicator.

=cut

sub initialize {
    my ($self) = @_;

    $self->add_arg_dependency(1, 1) unless $self->{'args'}->is_constant(1);
    $self->add_arg_dependency(2, 1) unless $self->{'args'}->is_constant(2);
}

sub create_buy_order {
    DFEATURE my $f;
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return DVAL 0 if (! $self->check_dependencies($calc, $i));

    my $price = $self->{'args'}->get_arg_values($calc, $i, 1);
    return DVAL $pf_manager->buy_conditional($calc, $sys_manager->get_name, $price);
}

sub create_sell_order {
    DFEATURE my $f;
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return DVAL 0 if (! $self->check_dependencies($calc, $i));

    my $price = $self->{'args'}->get_arg_values($calc, $i, 2);
    return DVAL $pf_manager->sell_conditional($calc, $sys_manager->get_name, $price);
}

1;
