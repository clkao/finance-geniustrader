package GT::Signals::Generic::False;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Carp::Datum;
use GT::Signals;
use GT::Eval;
use GT::Tools qw(:generic);

@ISA = qw(GT::Signals);
@NAMES = ("False");

=head1 False

Always return false.

=head2 EXAMPLE

    S:Generic:False

=cut
sub initialize {
    my ($self) = @_;

}

sub detect {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    $calc->signals->set($self->get_name, $i, 0);
}

1;
