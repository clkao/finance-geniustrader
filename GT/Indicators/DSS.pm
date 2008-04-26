package GT::Indicators::DSS;

# Copyright 2002 Oliver Bossert
# Updated 2006, 2008 by Karsten Wippler, Thomas Weigert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::ArgsTree;
use GT::Indicators;
use GT::Indicators::EMA;
use GT::Indicators::Generic::MinInPeriod;
use GT::Indicators::Generic::MaxInPeriod;

@ISA = qw(GT::Indicators);
@NAMES = ("DSS-BLAU[#1,#2,#3]");
@DEFAULT_ARGS = (5,7,3,"{I:Prices HIGH}","{I:Prices LOW}","{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::DSS - Double Smoothed Stochastic (William Blau).


=head1 DESCRIPTION 

From http://www.wealth-lab.com/cgi-bin/WealthLab.DLL/getdoc?id=128:

DSS applies 2 smoothing EMAs of different lengths to a Stochastic Oscillator.
DSS ranges from 0 to 100, like the standard Stochastic Oscillator. The same
rules of interpretation that you use for Stochastics can be applied to DSS,
although DSS offers a much smoother curve than Stochastics. 

From http://www.tradesignalonline.com/Lexicon/Default.aspx?name=DSS%3a+Double+Smoothed+Stochastics+(Blau)

Calculation of the DSS indicator is similar to stochastics. The numerator: 
first the difference between the current close and the period low is formed, 
and this is then exponentially smoothed twice. The denominator is formed in 
the same way, but here the difference is calculated from the period high minus
the period low. Numerator and denominator yield the quotient, and this value 
is multiplied by 100.

=head2 Calculation

As can be seen from above, there is some disagreement on the calculation
process. We follow the latter and calculate DSS-BLAU as follows:

DSS-BLAU[p1,p2,p3] = 
             EMA[p3, EMA[p2, Close - LowestLow[p1]]
   100 * ----------------------------------------------
         EMA[p3, EMA[p2, HighestHigh[p1]-LowestLow[p1]]

The handling and the calculations of signals is similar to the
Stochastic-Indictor.

=head2 Parameters

=over

=item Period 1 (default 5)

The period over which to consider highest highs and lowest lows.

=item Period 2 (default 7)

The period of the first smoothing

=item Period 3 (default 3)

The period of the second smoothing

=item High, Low, and Close of Source

The source from which the indicators is calculated.

=back

=cut


sub initialize {
    my ($self) = @_;
    my $args = $self->{'args'};

    for (my $i=1;$i<=3;$i++) {
      die "Argument $i to ".$self->get_name." must be a constant value.\n" unless $args->is_constant($i);
    }

    my $nb1 = $args->get_arg_names(1);
    my $nb2 = $args->get_arg_names(2);
    my $nb3 = $args->get_arg_names(3);

    my $min = "{I:Generic:Eval ".$args->get_arg_names(6)." - {I:Generic:MinInPeriod $nb1 ".$args->get_arg_names(5)."}}";
    my $max = "{I:Generic:Eval {I:Generic:MaxInPeriod $nb1 ".$args->get_arg_names(4)."} - {I:Generic:MinInPeriod $nb1 ".$args->get_arg_names(5)."}}";

    $self->{'num'} = GT::Indicators::EMA->new([$nb3, "{I:EMA $nb2 $min}"]);
    $self->{'den'} = GT::Indicators::EMA->new([$nb3, "{I:EMA $nb2 $max}"]);

    $self->add_prices_dependency( $nb1 + $nb2 + $nb3 );
    $self->add_indicator_dependency( $self->{'num'}, 1 );
    $self->add_indicator_dependency( $self->{'den'}, 1 );

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name();

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $den = $indic->get($self->{'den'}->get_name, $i) || 0.0000001;
    my $dss = 100 * $indic->get($self->{'num'}->get_name, $i) / $den;
    $indic->set($name, $i, $dss);
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name();

    return if ($calc->indicators->is_available_interval($name, $first, $last));
    return if (! $self->check_dependencies_interval($calc, $first, $last));

    for(my $i = $first; $i <= $last; $i++) {
      my $den = $indic->get($self->{'den'}->get_name, $i) || 0.0000001;
      my $dss = 100 * $indic->get($self->{'num'}->get_name, $i) / $den;
      $indic->set($name, $i, $dss);
    }
}

1;
