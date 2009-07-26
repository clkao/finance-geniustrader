package Finance::GeniusTrader::Signals::Generic::Increase;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Signals;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::Tools qw(:generic);

@ISA = qw(Finance::GeniusTrader::Signals);
@NAMES = ("Increase[#*]");

=head1 Increase Generic Signal

=head2 Overview

This Generic Signal will be able to tell you when a specific indicator is
increasing from its previous level.

=head2 EXAMPLE

You can use this signal to determine if the
securities closing price is increasing.

  S:Generic:Increase {I:Prices CLOSE}

=cut
sub initialize {
    my ($self) = @_;
    warn "Bad number of arguments given to S:Generic:Increase !" if ($self->{'args'}->get_nb_args() != 1);
}

sub detect {
    my ($self, $calc, $i) = @_;
    
    return if ($calc->signals->is_available($self->get_name, $i));
    return if ($i < 1);

    my $first = $self->{'args'}->get_arg_values($calc, $i - 1, 1);
    my $second = $self->{'args'}->get_arg_values($calc, $i, 1);
    
    return if (not (defined($first) && defined($second)));
    
    if ($first < $second) {
	$calc->signals->set($self->get_name, $i, 1);
    } else {
	$calc->signals->set($self->get_name, $i, 0);
    }
}

1;
