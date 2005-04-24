package GT::Analyzers::RiskReturn;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Analyzers;
use GT::Calculator;

@ISA = qw(GT::Analyzers);
@NAMES = ("RiskReturn[#*]");
@DEFAULT_ARGS = ("{A:CompleteValue}");

=head1 NAME

  GT::Analyzers::RiskReturn - Caluclates the Risk-/Return-Ratio

=head1 DESCRIPTION 

Caluclates the Risk-/Return-Ratio

=head2 Parameters

First argument: The portfolio-history.

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

    my @data = ();
    foreach my $j (0..$#{$array}) {
      $data[$j][0] = $j;
      $data[$j][1] = $array->[$j];
    }
    my $nb = $#{$array}+1;

    # Calculate the Linear Regression
    my ($sumxy, $sumx, $sumy, $sumx2, $sumy2) =(0, 0, 0, 0, 0);
    for (my $j=0; $j<($#data+1); $j++) {
      $sumxy += ($data[$j][0]*$data[$j][1]);
      $sumx += $data[$j][0];
      $sumy += $data[$j][1];
      $sumx2 += ($data[$j][0]*$data[$j][0]);
      $sumy2 += ($data[$j][1]*$data[$j][1]);
    }
    my $average_x = $sumx / $nb;
    my $average_y = $sumy / $nb;

    # Calculate b
    my $b = ( ($nb * $sumxy) - ($sumx * $sumy) ) / ( $nb * $sumx2 - $sumx**2  );
    my $a = $average_y - $b * $average_x;

    my $rss = 0;
    for (my $j=0; $j<($#data+1); $j++) {
      my $ty = $b * $j + $a;
      $rss += ($ty-$data[$j][1])**2;
    }
    my $sx = sqrt( ($sumx2-($sumx**2/$nb)) / $nb );
    my $sy = sqrt( ($sumy2-($sumy**2/$nb)) / $nb );

    $rss = sqrt( $rss / ($nb-2) );

    my $n = $#data + 1;
    my $R = ( $sumxy - ( ($sumx*$sumy)/$n ) ) / sqrt ( ($sumx2-$sumx*$sumx/$n) * ($sumy2-$sumy*$sumy/$n) ) 
      unless ( $n == 0 || sqrt ( ($sumx2-$sumx*$sumx/$n) * ($sumy2-$sumy*$sumy/$n) ) == 0);
    my $R2 = $R*$R;

    my $rrr = $b / $rss if ($rss != 0);

#    print " $rrr = $b / $rss \n";
    $calc->indicators->set($name, $last, $rrr);
}

1;
