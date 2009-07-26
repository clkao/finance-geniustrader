package GT::Analyzers::MeanPerformance;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("MeanPerformance[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

  GT::Analyzers::MeanPerformace - The Mean Performance of a Portfolio

=head1 DESCRIPTION 

The mean performance of the portfolio

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

    my $sum = 0;
    my $anz = 0;
    foreach my $position (@{$self->{'portfolio'}->{'history'}})
    {
	my $pstats = $position->stats($self->{'portfolio'});
	my $diff = $pstats->{'sold'} - $pstats->{'bought'} 
	    - $pstats->{'cost'};
	#print $diff . "\n";
	$sum += $diff;
	$anz++;
    }
    $sum = $sum / $anz if ($anz != 0);

    $calc->indicators->set($name, $last, $sum);
}

1;
