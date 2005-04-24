package GT::Analyzers::Accumulate;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("Accumulate[#*]");
@DEFAULT_ARGS = ("{A:Costs}");

=head1 NAME

  GT::Analyzers::Accumulate - Accumulates the Days of arg1

=head1 DESCRIPTION 

Accumulates the values of the array that is given as arg1.

This means if the array consists of the values (1,2,3,4) the result is
(1,3,6,10).


=head2 Parameters

First argument: Array reference to be accumulated


=head2 Return

Returns an array, not considering first and last parameter.

=cut

sub initialize {
    1;
}

sub calculate {
    my ($self, $calc, $last, $first, $portfolio) = @_;
    my $name = $self->get_name;

    if ( !defined($portfolio) ) {
	$portfolio = $calc->{'pf'};
    }
    if ( !defined($first) ) {
	$first = $calc->{'first'};
    }
    if ( !defined($last) ) {
	$last = $calc->{'last'};
    }

    my $array = $self->{'args'}->get_arg_values($calc, $last, 1);

    my $sum = 0;
    my @ret = ();
    foreach my $f (@{$array}) {
	$sum += $f;
	push @ret, $sum;
    }

    $calc->indicators->set($name, $last, \@ret );
}

1;
