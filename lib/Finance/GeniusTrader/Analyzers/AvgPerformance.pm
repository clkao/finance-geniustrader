package GT::Analyzers::AvgPerformance;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("AvgPerformance[#*]");
@DEFAULT_ARGS = ("{A:Sum {A:IsGain}}", "{A:Sum {A:IsLoss}}", "{A:Sum {A:NetGain}}", "{A:InitSum}");

=head1 NAME

  GT::Analyzers::AvgPerformance - Average Performance per trade

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

    my $nbg = $self->{'args'}->get_arg_values($calc, $last, 1);
    my $nbl = $self->{'args'}->get_arg_values($calc, $last, 2);
    my $gain = $self->{'args'}->get_arg_values($calc, $last, 3);
    my $init = $self->{'args'}->get_arg_values($calc, $last, 4);

    my $ret = 0;
    $ret = (1 + ($gain / $init) ) **( 1 / ($nbg + $nbl) ) - 1 unless( $init == 0 ||
								      ($nbg + $nbl) == 0 );

    $calc->indicators->set($name, $last, $ret);
}

1;
