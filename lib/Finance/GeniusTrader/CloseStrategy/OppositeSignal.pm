package Finance::GeniusTrader::CloseStrategy::OppositeSignal;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::CloseStrategy;

@ISA = qw(Finance::GeniusTrader::CloseStrategy);
@NAMES = ("OppositeSignal");

=head1 Finance::GeniusTrader::CloseStrategy::OppositeSignal

This strategy closes the position once the opposite signal has been emitted
by the system. It will will close a long position on a sell signal and
close a short position on a buy signal.

=cut

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

    if ($sys_manager->system->short_signal($calc, $i))
    {
	my $order = $pf_manager->sell_market_price($calc, 
						   $sys_manager->get_name);
	$pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
    
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    if ($sys_manager->system->long_signal($calc, $i))
    {
	my $order = $pf_manager->buy_market_price($calc, 
						  $sys_manager->get_name);
	$pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
   
    return;
}

