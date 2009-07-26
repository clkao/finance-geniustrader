package GT::Analyzers::Consec;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("Consec[#*]");
@DEFAULT_ARGS = ("{A:Costs}");

=head1 NAME

  GT::Analyzers::Consec - Maximum of consecutive nonzero-values

=head1 DESCRIPTION 

Calculates the Average of Arg1

=head2 Parameters

First argument: Array reference to be averaged

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

    my $max = 0;
    my $anz = 0;
    foreach my $f (@{$array})
    {
	if ($f != 0) {
	    $anz++;
	} else {
	    $max = $anz if ($anz > $max);
	    $anz = 0;
	}
    }

    $calc->indicators->set($name, $last, $max);
}

1;
