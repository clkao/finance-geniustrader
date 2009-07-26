package GT::Analyzers::SumPerformance;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("SumPerformance[#*]");
@DEFAULT_ARGS = ("{A:Sum {A:NetGain}}", "{A:InitSum}");

=head1 NAME

  GT::Analyzers::SumPerformance - The Sum of the Performance

=head1 DESCRIPTION 

The Sum of the Performance

=head2 Parameters

=over

=item Sum of the Gains

=item Initial Sum

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

    my $ret = 0;
    my $gain = $self->{'args'}->get_arg_values($calc, $last, 1);
    my $sum = $self->{'args'}->get_arg_values($calc, $last, 2);
    $ret = $gain / $sum if ($sum != 0);

    $calc->indicators->set($name, $last, $ret);
}

1;
