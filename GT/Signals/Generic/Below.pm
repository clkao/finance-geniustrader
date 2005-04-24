package GT::Signals::Generic::Below;

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
@NAMES = ("Below[#*]");

=head1 Below Generic Signal

=head2 Overview

This Generic Signal will be able to tell you when a specific indicator is
below something else which could be an other indicator, a limit or current prices.

=head2 EXAMPLE

You can check if the Security is trading below the
200 day Exponential Moving Average with this signal:

  S:Generic:Below {I:Prices CLOSE} {I:EMA 200}

=cut
sub initialize {
    my ($self) = @_;
    warn "Bad number of arguments given to S:Generic:Below !" if ($self->{'args'}->get_nb_args() != 2);
}

sub detect {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    
    return if ($calc->signals->is_available($self->get_name, $i));

    my $first = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $second = $self->{'args'}->get_arg_values($calc, $i, 2);

    return if not defined($first);
    return if not defined($second);
    
    if ($first < $second) {
	$calc->signals->set($self->get_name, $i, 1);
    } else {
	$calc->signals->set($self->get_name, $i, 0);
    }
}

1;
