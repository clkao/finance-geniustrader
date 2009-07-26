package Finance::GeniusTrader::Analyzers::DrawDown;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Analyzers;
use Finance::GeniusTrader::Calculator;

@ISA = qw(Finance::GeniusTrader::Analyzers);
@NAMES = ("DrawDown[#*]");
@DEFAULT_ARGS = ("{A:NetGain}", "{A:InitSum}", "{A:Max {A:NetGain}}");

=head1 NAME

  Finance::GeniusTrader::Analyzers::DrwaDown - The Drawdown of the portfolio

=head1 DESCRIPTION 

The Drawdown of the portfolio: The maximum Drawdown can be calculated
as: {A:Min {A:DrawDown}}

=head2 Parameters

=over

=item NetGain

=item Initial Sum of Cash

=item Maximum net gain

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

    my $gain = $self->{'args'}->get_arg_values($calc, $last, 1);
    my $sum = $self->{'args'}->get_arg_values($calc, $last, 2);
    my $max = $self->{'args'}->get_arg_values($calc, $last, 3);

    my @ret = ();
    foreach my $f (0..$#{$gain})
    {
	my $tmp = 0;
	$tmp = 1 - (($sum->[$f] + $gain->[$f]) / ($sum->[$f] + $max )) if (ref($sum) =~/ARRAY/ && 
									   $sum->[$f] != 0);
	$tmp = 1 - (($sum- + $gain->[$f]) / ($sum + $max )) if (ref($sum) !~/ARRAY/ && 
								$sum != 0);
	push @ret, $tmp;
    }

    $calc->indicators->set($name, $last, \@ret);

}

1;
