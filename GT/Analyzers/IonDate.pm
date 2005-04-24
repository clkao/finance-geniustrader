package GT::Analyzers::IonDate;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;
use GT::Prices;

@ISA = qw(GT::Analyzers);
@NAMES = ("IonDate[#*]");
@DEFAULT_ARGS = ("{I:SMA}", "{A:OpenDate}");

=head1 NAME

  GT::Analyzers::AvgCosts - Average Costs per trade

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

    my $array = $self->{'args'}->get_arg_values($calc, $last, 2);
    my @ret = ();

    foreach my $date (@{$array})
    {
      my $i = $calc->prices->find_nearest_date( $date );
      my $val = $self->{'args'}->get_arg_values($calc, $calc->prices->date($date), 1);
      $val ="NA" if ( !defined($val) );
#      print $date . "\t" . $calc->prices->date($date) . "\t" . $val . "\n";
      push @ret, $val;
    }

    $calc->indicators->set($name, $last, \@ret);
}

1;
