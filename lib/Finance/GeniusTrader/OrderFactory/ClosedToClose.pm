package GT::OrderFactory::ClosedToClose;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::OrderFactory;
use GT::Prices;

@ISA = qw(GT::OrderFactory);
@NAMES = ("ClosedToClose[#1]");
@DEFAULT_ARGS = (0);

=head1 NAME

GT::OrderFactory::StopOnExtreme

=head1 DESCRIPTION

Create an order that will be x% above or below current close prices.

=cut

sub initialize {
    my ($self) = @_;
    $self->add_arg_dependency(1, 1) unless $self->{'args'}->is_constant(1);
}

sub create_buy_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;
    
    $self->{'long_factor'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    
    my $price = $calc->prices->at($i)->[$CLOSE] * $self->{'long_factor'};
    return $pf_manager->buy_limited_price($calc, $sys_manager->get_name, $price);
}

sub create_sell_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    $self->{'short_factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    
    my $price = $calc->prices->at($i)->[$CLOSE] * $self->{'short_factor'};
    return $pf_manager->sell_conditional($calc, $sys_manager->get_name, $price);
}

1;
