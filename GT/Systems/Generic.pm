package GT::Systems::Generic;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Carp::Datum;
use GT::Prices;
use GT::Systems;
use GT::Eval;
use GT::Tools qw(:generic);

@ISA = qw(GT::Systems);
@NAMES = ("Generic[#*]");

=head1 Trend Following System (TFS)

=cut

sub initialize {
    my ($self) = @_;
}

sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;
}

sub long_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    
    return DVAL 0 if (! $self->check_dependencies($calc, $i));
    
    if ( $self->{'args'}->get_arg_values($calc, $i, 1) == 1 )
    {
	return DVAL 1;
    }
    return DVAL 0;
}

sub short_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    
    return DVAL 0 if (! $self->check_dependencies($calc, $i));

    if ( $self->{'args'}->get_nb_args() >= 2 && 
	 $self->{'args'}->get_arg_values($calc, $i, 2) == 1 )
    {
	return DVAL 1;
    }
    return DVAL 0;
}

1;
