package GT::Signals::Prices::InsidePrevious;

# Copyright 2003 Alexander Henkel
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Prices;

@ISA = qw(GT::Signals);
@NAMES = ("InsidePrevious");

=head1 GT::Signals::Prices::InsidePrevious

The InsidePrevious signal gets triggered if a security's high is lower than or equal to
the previous period's high, and the low is higher than or equal to previous period's
low.

=cut
sub initialize {
    my ($self) = @_;
    
    $self->add_prices_dependency(2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $q = $calc->prices;

    return if ($calc->signals->is_available($self->get_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # Check on Inside Day
    if ( ($q->at($i)->[$HIGH] <= $q->at($i-1)->[$HIGH]) &&
         ($q->at($i)->[$LOW]  >= $q->at($i-1)->[$LOW]) ) {
      $calc->signals->set($self->get_name, $i, 1);
    }
    else {
      $calc->signals->set($self->get_name, $i, 0);
    }
}

1;
