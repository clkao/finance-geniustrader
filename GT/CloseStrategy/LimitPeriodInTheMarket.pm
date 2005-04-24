package GT::CloseStrategy::LimitPeriodInTheMarket;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::CloseStrategy;
use GT::Prices;
use Carp::Datum;

@ISA = qw(GT::CloseStrategy);
@NAMES = ("LimitPeriodInTheMarket[#1]");
@DEFAULT_ARGS = (30, "{S:Generic:True}", "{S:Generic:True}");

=head1 NAME

GT::CloseStrategy::LimitPeriodInTheMarket - Only allow the trade to last for X days

=head1 DESCRIPTION

This strategy closes the position once the maximum time for the trade has been reached
if the second signal is true.

The second/third parameter is a signal which can infirm the closing order
of long/short position. In particular you may want to not close a position
which looks like to be a great winner...

You confirm the order with a true value and infirm it with a false value.

=head1 EXAMPLES

Close a long position if after 3 days, the security hasn't increased.
Close a short position if after 3 days, the security hasn't dropped.

 CS:LimitPeriodInTheMarket 3 
    {S:Generic:Below {I:Prices CLOSE} {I:Generic:PeriodAgo 3 {I:Prices CLOSE}}}
    {S:Generic:Above {I:Prices CLOSE} {I:Generic:PeriodAgo 3 {I:Prices CLOSE}}}
=cut

sub initialize {
    my $self = shift;
    $self->add_arg_dependency(2, 1);
}

sub long_position_opened {
    DFEATURE my $f;
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return DVOID;
}

sub short_position_opened {
    DFEATURE my $f;
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return DVOID;
}

sub manage_long_position {
    DFEATURE my $f;
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    my $initial_period = $calc->prices->date($position->{'open_date'});
    my $period_in_the_market = $self->{'args'}->get_arg_values($calc, $i, 1);
    
    return DVOID if (! $self->check_dependencies($calc, $i));
    
    return DVOID if (! $self->{'args'}->get_arg_values($calc, $i, 2));
    
    if (($i + 1) eq ($initial_period + $period_in_the_market)) {
	my $order = $pf_manager->sell_market_price($calc, $sys_manager->get_name);
	$pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
    
    return DVOID;
}

sub manage_short_position {
    DFEATURE my $f;
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    my $initial_period = $calc->prices->date($position->{'open_date'});
    my $period_in_the_market = $self->{'args'}->get_arg_values($calc, $i, 1);
    
    return DVOID if (! $self->check_dependencies($calc, $i));
    
    return DVOID if (! $self->{'args'}->get_arg_values($calc, $i, 3));

    if (($i + 1) eq ($initial_period + $period_in_the_market)) {
	my $order = $pf_manager->buy_market_price($calc, $sys_manager->get_name);
	$pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
   
    return DVOID;
}

