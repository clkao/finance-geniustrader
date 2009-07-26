package GT::Signals::Generic::Equal;

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
@NAMES = ("Equal[#*]");

=head1 Equal Generic Signal

=head2 Overview

This Generic Signal will be able to tell you when a specific indicator is
equal to something else which could be an other indicator, a limit or current prices.

=head2 EXAMPLE

You can use this signal to test if the securities
closing price equals 1.86

  S:Generic:Equal {I:Prices CLOSE} 1.86

=cut
sub initialize {
    my ($self) = @_;
    warn "Bad number of arguments given to S:Generic:Equal !" if ($self->{'args'}->get_nb_args() != 2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    return if ($calc->signals->is_available($self->get_name, $i));

    my $first = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $second = $self->{'args'}->get_arg_values($calc, $i, 2);
    
    return if (not (defined($first) && defined($second)));
    
    if ($first == $second) {
    	$calc->signals->set($self->get_name, $i, 1);
    } else {
	$calc->signals->set($self->get_name, $i, 0);
    }
}

1;
