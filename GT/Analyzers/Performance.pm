package GT::Analyzers::Performance;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("Performance[#*]");
@DEFAULT_ARGS = ("{A:NetGainPercent}", "{A:OpenPrice}");

=head1 NAME

  GT::Analyzers::Performance - The Performance of the trades

=head1 DESCRIPTION 

The Performance of the trades

=head2 Parameters

=over

=item The net gain in percent

=item The price ath the opening of a trade

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

    my @ret = ();
    foreach my $f (0..$#{$gain})
    {
	my $tmp = 0;
	$tmp = $gain->[$f] / $sum->[$f] if (ref($sum) =~/ARRAY/ && $sum->[$f] != 0);
	$tmp = $gain->[$f] / $sum if (ref($sum) !~/ARRAY/ && $sum != 0);
	push @ret, $tmp;
    }

    $calc->indicators->set($name, $last, \@ret);
}

1;
