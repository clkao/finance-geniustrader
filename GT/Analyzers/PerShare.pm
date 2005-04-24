package GT::Analyzers::PerShare;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("PerShare[#*]");
@DEFAULT_ARGS = ("{A:Costs}");

=head1 NAME

  GT::Analyzers::PerShare - Normalizes a value per share of a position

=head1 DESCRIPTION 

Normalizes a value per share of a position

=head2 Parameters

First argument: Array reference to be normalized

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

    if ( defined($portfolio) ) {
	$self->{'portfolio'} = $portfolio;
    }

    my $array = $self->{'args'}->get_arg_values($calc, $last, 1);

    # Check if portfolio has changed...
    return if ($#{$array} != $#{$self->{'portfolio'}->{'history'}});

    my @ret = ();
    foreach my $i (0..$#{$self->{'portfolio'}->{'history'}}) {
	my $position = $self->{'portfolio'}->{'history'}->[$i];
	my $pstats = $position->stats($self->{'portfolio'});
	$ret[$i] = $pstats->{'quantity'} != 0 ? $array->[$i] / $pstats->{'quantity'} : 0;
    }

    $calc->indicators->set($name, $last, \@ret);
}

1;
