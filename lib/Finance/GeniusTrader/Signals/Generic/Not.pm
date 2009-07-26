package Finance::GeniusTrader::Signals::Generic::Not;

# Copyright 2004 João Antunes Costa
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Signals;

@ISA = qw(Finance::GeniusTrader::Signals);
@NAMES = ("Not[#*]");

=head1 Not Signal Negation

=head2 Overview

This Generic Signal will reverse the value of the
signal parameter it receives.

=head2 EXAMPLE

You can use this signal to check if the closing prices
are not decreasing:

 S:Generic:Not {S:Generic:Decrease {I:Prices CLOSE}}

=cut
sub initialize {
    my ($self) = @_;
    warn "Bad number of arguments given to S:Generic:Not !" if ($self->{'args'}->get_nb_args() != 1);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $signals = $calc->signals;

    return if ($calc->signals->is_available($self->get_name, $i));
    my $value = $self->{'args'}->get_arg_values($calc, $i, 1);
    return if (! defined($value));
    if ($value) {
        $signals->set($self->get_name, $i, 0);
    } else {
        $signals->set($self->get_name, $i, 1);
    }
}

1;
