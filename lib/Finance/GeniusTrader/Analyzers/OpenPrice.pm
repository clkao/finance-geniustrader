package Finance::GeniusTrader::Analyzers::OpenPrice;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Analyzers;
use Finance::GeniusTrader::Calculator;

@ISA = qw(Finance::GeniusTrader::Analyzers);
@NAMES = ("OpenPrice[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

  Finance::GeniusTrader::Analyzers::OpenPrice - The price at the opening

=head1 DESCRIPTION 

The price at the opening

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
      push @ret, $position->open_price();
    }

    $calc->indicators->set($name, $last, \@ret);
}

1;
