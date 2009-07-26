package Finance::GeniusTrader::Analyzers::AvgGain;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Analyzers;
use Finance::GeniusTrader::Calculator;

@ISA = qw(Finance::GeniusTrader::Analyzers);
@NAMES = ("AvgGain[#*]");
@DEFAULT_ARGS = ("{A:CumGain}", "{A:Sum {A:IsGain}}");

=head1 NAME

  Finance::GeniusTrader::Analyzers::AvgGain - Average Gain per trade

=head1 DESCRIPTION 

This analyzer calculates the mean of the gains.

=head2 Parameters

First parameter: Cumulated Gain

Second parameter: Number of Gains

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

    my $cum = $self->{'args'}->get_arg_values($calc, $last, 1);
    my $nb = $self->{'args'}->get_arg_values($calc, $last, 2);
    my $ret = 0;
    $ret =  $cum ** (1 / $nb) - 1 if ($nb != 0);

    $calc->indicators->set($name, $last, $ret);
}

1;
