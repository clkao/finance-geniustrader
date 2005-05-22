package GT::MoneyManagement::FixedShares;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Prices;

@NAMES = ("FixedShares[#1]");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::FixedShares

=head2 Overview

This money management rule will allowed to each trade exactly the same
number of shares. The default number is set up to 100 shares.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ 100 ] };

    $args->[0] = 100 if (! defined($args->[0]));
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
 
    return $self->{'args'}[0];
}

1;
