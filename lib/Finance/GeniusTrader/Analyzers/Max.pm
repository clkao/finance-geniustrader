package Finance::GeniusTrader::Analyzers::Max;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Analyzers;
use Finance::GeniusTrader::Calculator;

@ISA = qw(Finance::GeniusTrader::Analyzers);
@NAMES = ("Max[#*]");
@DEFAULT_ARGS = ("{A:Costs}");

=head1 NAME

  Finance::GeniusTrader::Analyzers::Max - Calculates the Maximum of Arg1

=head1 DESCRIPTION 

Calculates the Maximum of Arg1

=head2 Parameters

First argument: Array reference

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

    my $erg = $array->[0];
    foreach my $f (@{$array})
    {
      $erg = $f if ($f > $erg);
    }

    $calc->indicators->set($name, $last, $erg);
}

1;
