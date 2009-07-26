package GT::CloseStrategy::Systems::TFS;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Prices;
use GT::CloseStrategy;
use GT::Indicators::TETHER;

@ISA = qw(GT::CloseStrategy);
@NAMES = ("TFS[#1]");

=head1 CloseStrategy of Trend Following System (TFS)

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [50] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;

    $self->{'tether'} = GT::Indicators::TETHER->new([ $self->{'args'}[0] ]);

    $self->add_indicator_dependency($self->{'tether'}, 2);
    $self->add_prices_dependency(1);
}


sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    $self->{'tether'}->calculate($calc, $i);
    
    # Eventually close the position or invert it
    if ($calc->prices->at($i)->[$CLOSE] < 
	$calc->indicators->get($self->{'tether'}->get_name, $i))
    {
	my $order = $pf_manager->sell_market_price($calc, 
						   $sys_manager->get_name);
	$pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    $self->{'tether'}->calculate($calc, $i);

    if ($calc->prices->at($i)->[$CLOSE] >
	$calc->indicators->get($self->{'tether'}->get_name, $i))
    {
	my $order = $pf_manager->buy_market_price($calc,
						  $sys_manager->get_name);
	$pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
    return;
}

