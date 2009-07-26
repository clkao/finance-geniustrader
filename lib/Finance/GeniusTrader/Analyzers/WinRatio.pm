package Finance::GeniusTrader::Analyzers::WinRatio;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Analyzers;
use Finance::GeniusTrader::Calculator;

@ISA = qw(Finance::GeniusTrader::Analyzers);
@NAMES = ("WinRatio[#*]");
@DEFAULT_ARGS = ("{A:Sum {A:IsGain}}", "{A:Sum {A:IsLoss}}");

=head1 NAME

  Finance::GeniusTrader::Analyzers::WinRatio - Calcuates the WinRatio

=head1 DESCRIPTION 

Calcuates the WinRatio

=head2 Parameters

=over

=item Number of Gains

=item Number of Losses

=back

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

    my $nbg = $self->{'args'}->get_arg_values($calc, $last, 1);
    my $nbl = $self->{'args'}->get_arg_values($calc, $last, 2);
    my $ret = 0;
    $ret = $nbg / ( $nbg + $nbl ) if ( $nbg + $nbl != 0);

    $calc->indicators->set($name, $last, $ret);
}

1;
