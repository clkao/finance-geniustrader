package GT::Signals::Generic::Decrease;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Eval;
use GT::Tools qw(:generic);

@ISA = qw(GT::Signals);
@NAMES = ("Decrease[#*]");

=head1 Decrease Generic Signal

=head2 Overview

This Generic Signal will be able to tell you when a specific indicator is
decreasing from its previous level.

=head2 EXAMPLE

You can use this signal to determine if the
securities closing price is decreasing

  S:Generic:Decrease {I:Prices CLOSE}

=cut
sub initialize {
    my ($self) = @_;
    warn "Bad number of arguments given to S:Generic:Decrease !" if ($self->{'args'}->get_nb_args() != 1);
}

sub detect {
    my ($self, $calc, $i) = @_;
    
    return if ($calc->signals->is_available($self->get_name, $i));
    return if ($i < 1);

    my $first = $self->{'args'}->get_arg_values($calc, $i - 1, 1);
    my $second = $self->{'args'}->get_arg_values($calc, $i, 1);
    
    return if (not (defined($first) && defined($second)));
    
    if ($first > $second) {
	$calc->signals->set($self->get_name, $i, 1);
    } else {
	$calc->signals->set($self->get_name, $i, 0);
    }
}

1;
