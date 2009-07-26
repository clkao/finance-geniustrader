package GT::Analyzers::Short;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("Short[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

  GT::Analyzers::Short - True if it is a short trade

=head1 DESCRIPTION 

True if it is a short trade

=head2 Parameters

none

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

    my @ret = ();
    foreach my $position (@{$self->{'portfolio'}->{'history'}}) {
      push @ret, ($position->{'long'}==0 ? 1 : 0);
    }

    $calc->indicators->set($name, $last, \@ret);
}

1;
