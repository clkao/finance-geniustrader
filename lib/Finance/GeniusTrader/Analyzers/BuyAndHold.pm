package GT::Analyzers::BuyAndHold;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;
use GT::Prices;

@ISA = qw(GT::Analyzers);
@NAMES = ("BuyAndHold[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

  GT::Analyzers::AvgCosts - Average Costs per trade

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

    my $buyhold = $calc->prices->at($last)->[$LAST] /
	$calc->prices->at($first)->[$LAST] - 1;

    $calc->indicators->set($name, $last, $buyhold);
}

1;
