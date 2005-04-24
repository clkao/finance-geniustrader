package GT::Analyzers::Duration;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("Duration[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

  GT::Analyzers::Duration - Duration of the trades

=head1 DESCRIPTION 

Duration of the trades.

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

    my @ret = ();
    foreach my $position (@{$portfolio->{'history'}}) {
      my $open  = $calc->prices->date( $position->{'open_date'} );
      my $close = $calc->prices->date( $position->{'close_date'} );
      push @ret, ($close-$open);
    }

    $calc->indicators->set($name, $last, \@ret);
}

1;
