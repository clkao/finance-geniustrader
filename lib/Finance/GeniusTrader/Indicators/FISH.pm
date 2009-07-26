package Finance::GeniusTrader::Indicators::FISH;

# Copyright 2008 Karsten Wippler
# Based on and for GeniusTrader (C) 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id: FISH.pm,v 1.4 2008/03/14 17:06:09 ras Exp ras $

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::ArgsTree;
use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::EMA;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("FISH[#1]","RAW[#1]");
@DEFAULT_ARGS = (10, "{I:MEAN}" );

=head1 Finance::GeniusTrader::Indicators::FISH

=head2 Overview
Infos cited from chart manual at
http://www.geocities.com/
user42_kevin/chart/index.html

The fisher transform indicator by John Ehlers is a range oscillator
showing where today's price is within the past N-days highest and lowest,
with some smoothing is used plus what's known in mathematics as a fisher transform.
This is similar to Stochastics and Williams %R  but the transformation stretches
values near the high and low, helping to highlight extremes.
=head2 Calculation

The calculation is as follows. The prices used are the midpoint between the day's
high and low (as in most of Ehlers' indicators). Today's price is located within
the highest and lowest of those prices from the past N days, scaled to -1 for the
low and 1 for the high.

     price = (high + low) / 2
     
                 price - Ndaylow
     raw = 2 * ------------------ - 1
               Ndayhigh - Ndaylow

This raw position is smoothed by a 5-day EMA and a log form which is the 
mathematical fisher transform, before a final further 3-day EMA smoothing.

     smoothed = EMA[5] of raw
     
                                  1 + smoothed
     fisher = EMA[3] of 0.5 * log ------------
                                  1 - smoothed

=head2 Parameters

The standard Fisher-Transform works with a 10-days parameter : n = 10

=head2 Links
http://mesasoftware.com/technicalpapers.htm
http://www.geocities.com/user42_kevin/chart/index.html

=head2 Creation

 Finance::GeniusTrader::Indicators::FISH->new()
 Finance::GeniusTrader::Indicators::FISH->new([20])

If you need a 30 days Fisher Transform of the opening prices you can write
one of those lines :

 Finance::GeniusTrader::Indicators::FISH->new([30, "{I:Prices OPEN}"])

A 10 days Fisher Transform  of the RSI could be created with :

 Finance::GeniusTrader::Indicators::FISH->new([10, "{I:RSI}"])


=cut
sub initialize {
    my ($self) = @_;
    
    $self->{'ema1'} = Finance::GeniusTrader::Indicators::EMA->new([5,"{I:Generic::Eval ({I:STO/1 ".
	    $self->{'args'}->get_arg_names(1) . " 1 1 1" .
	    $self->{'args'}->get_arg_names(2) ."})/50 - 1}" ]);

    $self->{'ema2'} = Finance::GeniusTrader::Indicators::EMA->new([3,"{I:Generic:ByName " . $self->get_name(1) . "}" ]);


    # Smoothing functions are args 2 and 3
    my $nb_days = $self->{'args'}->get_arg_names(1) + 8;

    $self->add_indicator_dependency($self->{'ema1'}, 5);
    $self->add_arg_dependency(2, $nb_days);

    
}

=pod

=head2 Finance::GeniusTrader::Indicators::SMI::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $ema1_name = $self->{'ema1'}->get_name;
    my $name = $self->get_name(0);
    my $raw1_name = $self->get_name(1);
    
    return if ($indic->is_available($raw1_name, $i) &&
	       $indic->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    for (my $n = 0; $n < 3; $n++) {

	# Return if RAW1 is available
	next if $indic->is_available($raw1_name, $i - $n);
	
        # Calculate CM
        my $sraw = $indic->get($ema1_name, $i - $n);
	my $lraw_value = (abs($sraw) > 0.999) ?
           $sraw/abs($sraw)*0.999 : $sraw;
        my $raw1_value = log((1+$lraw_value)/(1-$lraw_value));

	# Return the results
	$indic->set($raw1_name, $i - $n, $raw1_value);
    }
       # Return the results
       $self->{'ema2'}->calculate($calc, $i);
       my $fish=$indic->get($self->{'ema2'}->get_name, $i);
       $indic->set($name, $i, $fish);

}
1;
