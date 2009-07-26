package GT::Analyzers::ClosePrice;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("ClosePrice[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

  GT::Analyzers::ClosePricce - The price on the closing date

=head1 DESCRIPTION 

The price on the closing date.

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

    # FIXME: Why is the closing_price not stored?
    my @ret = ();
    foreach my $position (@{$self->{'portfolio'}->{'history'}}) {
      push @ret, $position->{'details'}->[1]->{'price'};
    }

    $calc->indicators->set($name, $last, \@ret);
}

1;
