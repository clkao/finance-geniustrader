package Finance::GeniusTrader::Signals::Generic::And;

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
@NAMES = ("And[#*]");

=head1 And Combination Signals

=head2 Overview

This Generic Signal will be give a positive signals only when all
mentionned signals also give positive signals.

=head2 EXAMPLE

You can use this signal to check if the closing prices is above
10 and below 15 :

 S:Generic:And {S:Generic:Above {I:Prices CLOSE} 10} {S:Generic:Below {I:Prices CLOSE} 15}

=cut
sub initialize {
    my ($self) = @_;
    warn "Bad number of arguments given to S:Generic:And !" if ($self->{'args'}->get_nb_args() < 2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $signals = $calc->signals;
    
    return if ($calc->signals->is_available($self->get_name, $i));

    my $defined = 0;
    for (my $n = 1; $n <= $self->{'args'}->get_nb_args; $n++)
    {
	my $value = $self->{'args'}->get_arg_values($calc, $i, $n);
	next if (! defined($value));
	$defined = 1;
	if (! $value) {
	    $signals->set($self->get_name, $i, 0);
	    return;
	}
    }
    if ($defined) {
	$signals->set($self->get_name, $i, 1);
    }
}

1;
