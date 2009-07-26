package Finance::GeniusTrader::Indicators::FRAMA;

# Copyright 2008 Karsten Wippler
# Based on and for GeniusTrader (C) 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id: FRAMA.pm,v 1.4 2008/03/14 17:07:14 ras Exp ras $

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::SMA;
use Finance::GeniusTrader::Indicators::Generic::MinInPeriod;
use Finance::GeniusTrader::Indicators::Generic::MaxInPeriod;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("FRAMA[#*]","ALPHA[#1]");
@DEFAULT_ARGS = (16, "{I:MEAN}");

=head1 NAME

Finance::GeniusTrader::Indicators::FRAMA - FRactal Adaprive Moving Average

=head1 DESCRIPTION

An exponential moving average gives more importance to
recent prices ... similarly a Frama uses a variable 
(adaptive) alpha

=head2 Parameters

=over

=item Period (default 20)

The first argument is the period used to calculed the average.

=item Other data input

The second argument is optional. It can be used to specify an other
stream of input data for the average instead of the close prices.
This is usually an indicator (detailed via {I:MyIndic <param>}).

=back

=head2 Calculation
The alpha is calculated following 
http://www.mesasoftware.com/technicalpapers.htm
see the self explaining code below :D
when knowing the alpha FRAMA is
FRAMA[n] = FRAMA[n-1] + alpha * ( INPUT - FRAMA[n-1] )

In TA, the first value is often constructed as SMA(N).

Note: One criticism could be that the EMA is calculated starting
from the designated period. But actually the EMA goes all the way back
to the beginning of the available data. But in all tools I checked they
start computation from the loaded data on.

=head2 Creation

 Finance::GeniusTrader::Indicators::FRAMA->new()
 Finance::GeniusTrader::Indicators::FRAMA->new([20])

If you need a 30 days FRAMA of the opening prices you can write
one of those lines :

 Finance::GeniusTrader::Indicators::FRAMA->new([30, "{I:Prices OPEN}"])

A 10 days EMA of the RSI could be created with :

 Finance::GeniusTrader::Indicators::FRAMA->new([10, "{I:RSI}"])

 note!!! The number of days has to be EVEN!!

Z<>

=cut
sub initialize {
    my ($self) = @_;
    my $period = $self->{'args'}->get_arg_names(1);
    $period=$period/2;
    $self->{'hmin'} = Finance::GeniusTrader::Indicators::Generic::MinInPeriod->new([ $period, $self->{'args'}->get_arg_names(2)  ]);
    $self->{'hmax'} = Finance::GeniusTrader::Indicators::Generic::MaxInPeriod->new([ $period, $self->{'args'}->get_arg_names(2)  ]);
    $self->{'min'} = Finance::GeniusTrader::Indicators::Generic::MinInPeriod->new([ $self->{'args'}->get_arg_names(1), 
								 $self->{'args'}->get_arg_names(2)  ]);
    $self->{'max'} = Finance::GeniusTrader::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_names(1), 
								 $self->{'args'}->get_arg_names(2)  ]);

    $self->{'sma'} = Finance::GeniusTrader::Indicators::SMA->new([ $self->{'args'}->get_arg_names() ]);
    $self->add_indicator_dependency($self->{'sma'}, 1);
    $self->add_indicator_dependency($self->{'hmin'},  $self->{'args'}->get_arg_names(1));
    $self->add_indicator_dependency($self->{'hmax'},  $self->{'args'}->get_arg_names(1));
    $self->add_indicator_dependency($self->{'min'},  $self->{'args'}->get_arg_names(1));
    $self->add_indicator_dependency($self->{'max'},  $self->{'args'}->get_arg_names(1));
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
        my $name = $self->get_name(0);
        my $alpha_name = $self->get_name(1);
    my $hmin_name = $self->{'hmin'}->get_name;
    my $hmax_name = $self->{'hmax'}->get_name;
    my $min_name = $self->{'min'}->get_name;
    my $max_name = $self->{'max'}->get_name;
    my $before = 1;

    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    return if (! defined($nb));
    my $period=$nb/2;

    return if ($indic->is_available($name, $i));
    return if ($before && ! $self->check_dependencies($calc, $i));

   my $alpha = 0.5;

    my $oldframa = $indic->get($name, $i - 1);
    my $frama;
    if (defined $oldframa) {
      my $low1 = $indic->get($hmin_name, $i - $period);
      my $high1 = $indic->get($hmax_name, $i - $period);
      my $low2 = $indic->get($hmin_name, $i);
      my $high2 = $indic->get($hmax_name, $i);
      my $low3 = $indic->get($min_name, $i);
      my $high3 = $indic->get($max_name, $i);
      my $N1= ($high1-$low1)/$period;
      my $N2= ($high2-$low2)/$period;
      my $N3= ($high3-$low3)/$nb;
      my $dim;
      if ($N1>0 && $N2>0 && $N3>0){
      $dim=(log($N1+$N2)-log($N3))/log(2);
      }
      $alpha=exp(-4.6*($dim-1));
      if ($alpha <0.01){
      $alpha=0.01;
      }
      if ($alpha >1){
      $alpha=1;
      }
      $frama = $alpha * ($self->{'args'}->get_arg_values($calc, $i, 2) - $oldframa) + $oldframa;
    } else {
      $frama = $indic->get($self->{'sma'}->get_name, $i);
      $before = 0;
    }
        $indic->set($alpha_name, $i, $alpha);
    $indic->set($name, $i, $frama);

}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $indic = $calc->indicators;
        my $name = $self->get_name(0);
        my $alpha_name = $self->get_name(1);
    my $hmin_name = $self->{'hmin'}->get_name;
    my $hmax_name = $self->{'hmax'}->get_name;
    my $min_name = $self->{'min'}->get_name;
    my $max_name = $self->{'max'}->get_name;

    my $nb = $self->{'args'}->get_arg_constant(1);
    return if (! defined($nb));
    return if ($indic->is_available_interval($name, $first, $last));
    # Don't need to calculate all SMA values, just the first data point.
        $self->{'sma'}->calculate($calc, $first);
    while (! $self->check_dependencies_interval($calc, $first, $last)) {
      return if $first == $last;
      $first++;
    }
    my $period=$nb/2;
    my $alpha = 0.5;

    $indic->set($name, $first, $indic->get($self->{'sma'}->get_name, $first));

    for (my $i=$first+1;$i<=$last;$i++) {
      my $low1 = $indic->get($hmin_name, $i - $period);
      my $high1 = $indic->get($hmax_name, $i - $period);
      my $low2 = $indic->get($hmin_name, $i);
      my $high2 = $indic->get($hmax_name, $i);
      my $low3 = $indic->get($min_name, $i);
      my $high3 = $indic->get($max_name, $i);
      my $N1= ($high1-$low1)/$period;
      my $N2= ($high2-$low2)/$period;
      my $N3= ($high3-$low3)/$nb;
      my $dim;
      if ($N1>0 && $N2>0 && $N3>0){
      $dim=(log($N1+$N2)-log($N3))/log(2);
      }
      $alpha=exp(-4.6*($dim-1));
      if ($alpha <0.01){
      $alpha=0.01;
      }
      if ($alpha >1){
      $alpha=1;
      }
      my $oldframa = $indic->get($name, $i - 1);
      my $frama = $alpha * ($self->{'args'}->get_arg_values($calc, $i, 2) - $oldframa) + $oldframa;
                $indic->set($alpha_name, $i, $alpha);
      $indic->set($name, $i, $frama);
    }
}

1;
