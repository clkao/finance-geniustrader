package GT::OrderFactory::StopOnExtreme;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::OrderFactory;
use GT::Prices;

@ISA = qw(GT::OrderFactory);
@NAMES = ("StopOnExtreme[#1,#2]");
@DEFAULT_ARGS = (0.5, 1);

=head1 NAME

GT::OrderFactory::StopOnExtreme

=head1 DESCRIPTION

Create a "stop" order that will with the limit the high of the day (modulo
x%) for a long position and the low of the day for a short position.

=cut
sub initialize {
    my ($self) = @_;
    $self->add_arg_dependency(1, 1) unless $self->{'args'}->is_constant(1);
    $self->add_arg_dependency(2, 1) unless $self->{'args'}->is_constant(2);
}

sub create_buy_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;
    
    return if (! $self->check_dependencies($calc, $i));

    $self->{'long_factor'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    $self->{'long_second'} = 1 + $self->{'args'}->get_arg_values($calc, $i, 2) / 100;
    
    my $stop = $calc->prices->at($i)->[$HIGH] * $self->{'long_factor'};
    return $pf_manager->buy_conditional($calc, $sys_manager->get_name,
				$stop, $stop * $self->{'long_second'});
}

sub create_sell_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return if (! $self->check_dependencies($calc, $i));
    
    $self->{'short_factor'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 1) / 100;
    $self->{'short_second'} = 1 - $self->{'args'}->get_arg_values($calc, $i, 2) / 100;
    
    my $stop = $calc->prices->at($i)->[$LOW] * $self->{'short_factor'};
    return $pf_manager->sell_conditional($calc, $sys_manager->get_name,
				$stop, $stop * $self->{'short_second'});
}

1;
