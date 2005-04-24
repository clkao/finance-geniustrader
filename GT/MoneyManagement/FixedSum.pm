package GT::MoneyManagement::FixedSum;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Prices;
use Carp::Datum;

@NAMES = ("FixedSum[#1]");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::FixedSum

=head2 Overview

This money management rule will invest the same amount of money in each
trade. The default value is set up to 1000.

=cut

sub new {
    DFEATURE my $f, "new MoneyManagement";
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ 1000 ] };

    $args->[0] = 1000 if (! defined($args->[0]));
    
    return DVAL manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    DFEATURE my $f;
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $investment = $self->{'args'}[0];
 
    if (!defined($order->{'quantity'})) {
	if ($order->{'price'}) {
	    return DVAL int($investment / $order->{'price'});
	} else {
	    return DVAL int($investment / $calc->prices->at($i)->[$LAST]);
	}
    }
}

1;
