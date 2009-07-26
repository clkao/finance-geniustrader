package GT::Analyzers::NetGain;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("NetGain[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

  GT::Analyzers::NetGain - The net gain of the positions

=head1 DESCRIPTION 

The net gain of the positions

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
	my $pstats = $position->stats($portfolio);
	my $diff = $pstats->{'sold'} - $pstats->{'bought'} - $pstats->{'cost'};
	my $var = 0;
	if ($position->is_long) {
	    $var = ( $pstats->{'bought'} != 0 ) ? 
		( $diff / $pstats->{'bought'} ) : 0;
	} else {
	    $var = ($pstats->{'sold'} !=0 ) ? 
		( $diff / $pstats->{'sold'} ) : 0;
	}
	push @ret, $diff;
    }

    $calc->indicators->set($name, $last, \@ret);
}

1;
