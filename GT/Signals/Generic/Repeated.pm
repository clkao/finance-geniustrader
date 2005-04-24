package GT::Signals::Generic::Repeated;

# Copyright 2000-2002 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Carp::Datum;
use GT::Signals;

@ISA = qw(GT::Signals);
@NAMES = ("Repeated[#*]");

=head1 NAME

GT::Signals::Generic::Repeated - Detect repetition of a given signal

=head2 DESCRIPTION

This generic Signal will give a positive signal when the mentionned signal
has been positive for the last X days (where X is the second parameter of this
signal with a default value of 2).

=head2 EXAMPLE

You can check if the RSI has been above 80 for the last 3 days with this
signal:

  S:Generic:Repeated {S:Generic:Above {I:RSI} 80} 3

=cut
sub initialize {
    my ($self) = @_;
    warn "Bad number of arguments given to S:Generic:Repeated !" if ($self->{'args'}->get_nb_args() < 1 || $self->{'args'}->get_nb_args() > 2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $signals = $calc->signals;
    
    return if ($calc->signals->is_available($self->get_name, $i));

    my $defined = 0;
    my $nb = ($self->{'args'}->get_nb_args() > 1) ? $self->{'args'}->get_arg_values($calc, $i, 2) : 2;
    for (my $n = 0; $n < $nb; $n++)
    {
	my $value = $self->{'args'}->get_arg_values($calc, $i - $n, 1);
	if (! (defined($value) && $value)) {
	    $signals->set($self->get_name, $i, 0);
	    return;
	}
	$defined = 1;
    }
    if ($defined) {
	$signals->set($self->get_name, $i, 1);
    }
}

1;
