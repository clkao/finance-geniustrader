package GT::Analyzers::IsLoss;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("IsLoss[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

  GT::Analyzers::IsLoss - Boolean value: True if it is a loosing trade

=head1 DESCRIPTION 

Boolean value: True if it is a loosing trade

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
	my $pstats = $position->stats($self->{'portfolio'});
	my $diff = $pstats->{'sold'} - $pstats->{'bought'} - $pstats->{'cost'};
	my $var = 0;
	if ($position->is_long) {
	    $var = ( $pstats->{'bought'} != 0 ) ? 
		( $diff / $pstats->{'bought'} ) : 0;
	} else {
	    $var = ($pstats->{'sold'} !=0 ) ? 
		( $diff / $pstats->{'sold'} ) : 0;
	}
	if ( $diff < 0 ) {
	    push @ret, 1;
	} else {
	    push @ret, 0;
	}
    }

    $calc->indicators->set($name, $last, \@ret);
}

1;
