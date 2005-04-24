package GT::MoneyManagement::FixedFractional;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Prices;
use Carp::Datum;

@NAMES = ("FixedFractional[#1]");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::FixedFractional

=head2 Overview

This money management rule will allowed to each trade a fixed fraction of
the current portfolio value.

=cut

sub new {
    DFEATURE my $f, "new MoneyManagement";
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ 100 ] };

    $args->[0] = 100 if (! defined($args->[0]));
    
    return DVAL manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    DFEATURE my $f;
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $ratio = $self->{'args'}[0] / 100;

    # Initialization of portfolio value
    my $cash = $portfolio->current_cash;
    my $positions = $portfolio->current_evaluation;
    my $upcoming_gains_or_losses = $portfolio->current_marged_gains;
    my $portfolio_value = $cash + $positions + $upcoming_gains_or_losses;

    if ($order->{'price'}) {
	return DVAL int(($portfolio_value * $ratio) / $order->{'price'});
    } else {
	return DVAL int(($portfolio_value * $ratio) / $calc->prices->at($i)->[$LAST]);
    }
}

1;
