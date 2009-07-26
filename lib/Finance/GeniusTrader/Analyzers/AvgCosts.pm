package Finance::GeniusTrader::Analyzers::AvgCosts;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

# DELETE MARK

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Analyzers;
use Finance::GeniusTrader::Calculator;

@ISA = qw(Finance::GeniusTrader::Analyzers);
@NAMES = ("AvgCosts[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

  Finance::GeniusTrader::Analyzers::AvgCosts - Average Costs per trade

=head1 DESCRIPTION 

The mean costs of the portfolio

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
	$sum += $pstats->{'cost'};
	$anz++;
    }
    $sum = $sum / $anz if ($anz != 0);

    $calc->indicators->set($name, $last, $sum);
}

1;
