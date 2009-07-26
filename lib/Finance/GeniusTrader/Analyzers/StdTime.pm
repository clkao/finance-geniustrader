package Finance::GeniusTrader::Analyzers::StdTime;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Analyzers;
use Finance::GeniusTrader::Calculator;
use Finance::GeniusTrader::Conf;
use Finance::GeniusTrader::DateTime;

@ISA = qw(Finance::GeniusTrader::Analyzers);
@NAMES = ("StdTime[#*]");
@DEFAULT_ARGS = ("{A:Sum {A:Costs}}");

=head1 NAME

  Finance::GeniusTrader::Analyzers::StdTime - Normalizes the value #arg1 per year

=head1 DESCRIPTION 

Normalizes the value #arg1 per year

=head2 Parameters

First argument: Value to be normalizes

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

    my $val = $self->{'args'}->get_arg_values($calc, $last, 1);

    Finance::GeniusTrader::Conf::default("Analysis::ReferenceTimeFrame", "year");
    my $tf_name = Finance::GeniusTrader::Conf::get("Analysis::ReferenceTimeFrame");

    my $ref_tf = Finance::GeniusTrader::DateTime::name_to_timeframe($tf_name);
    my $exp = Finance::GeniusTrader::DateTime::timeframe_ratio($ref_tf, $calc->current_timeframe) 
	/ ($last - $first + 1);
    $val = (($val + 1) ** $exp) - 1;

    $calc->indicators->set($name, $last, $val);
}

1;
