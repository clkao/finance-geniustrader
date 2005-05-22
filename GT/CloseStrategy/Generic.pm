package GT::CloseStrategy::Generic;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Prices;
use GT::CloseStrategy;
use GT::Eval;
use GT::Tools qw(:generic);

@ISA = qw(GT::CloseStrategy);
@NAMES = ("Generic[#*]");
@DEFAULT_ARGS = ("{S:Generic:False}", "{S:Generic:False}");

=head1 NAME

CloseStrategy::Generic

=head1 DESCRIPTION 

This is a simple Generic Closestrategy that closes the trade based on
one or two signals.

=head2 Parameters

=over

=item First Signal

The first Signal is the signal used to close a long position.

=item Second Signal

The second signal is used to close short positions.

=back

=cut

sub initialize {
    my ($self) = @_;
}

sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return 0 if (! $self->check_dependencies($calc, $i));
    
    if ( $self->{'args'}->get_arg_values($calc, $i, 1) == 1 )
    {
        my $order = $pf_manager->sell_market_price($calc, 
                                                   $sys_manager->get_name);
        $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
    
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    return if (! $self->check_dependencies($calc, $i));

    if ( $self->{'args'}->get_nb_args() >= 2 && 
	 $self->{'args'}->get_arg_values($calc, $i, 2) == 1 )
    {
        my $order = $pf_manager->buy_market_price($calc, 
                                                  $sys_manager->get_name);
        $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
   
    return;
}

1;
