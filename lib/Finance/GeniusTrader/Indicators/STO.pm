package Finance::GeniusTrader::Indicators::STO;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Copyright 2008 by Karsten Wipple and Thomas Weigert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# based on version dated 24 Apr 2005, 7914 bytes
# significant improvements Karsten Wipple and Thomas Weigert
# $Id$

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::SMA;
use Finance::GeniusTrader::Indicators::Generic::MinInPeriod;
use Finance::GeniusTrader::Indicators::Generic::MaxInPeriod;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("\%K Fast[#1]","\%D Fast[#1,#2]","\%K Slow[#1,#3]","\%D Slow[#1,#3,#4]");
@DEFAULT_ARGS = (5, 3, 3, 3, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}" );

=pod

=head1 Finance::GeniusTrader::Indicators::STO

=head2 Overview

Developed by George C. Lane in the late 1950s, the Stochastic Oscillator
is a momentum indicator that shows the location of the current close
relative to the high/low range over a set number of periods. Closing
levels that are consistently near the top of the range indicate
accumulation (buying pressure) and those near the bottom of the range
indicate distribution (selling pressure).

=head2 Calculation

%K Fast = 100 * ((Last - Lowest Low(n)) / (Highest High(n) - Lowest Low(n)))
 %D Fast = M-periods SMA of %K Fast

 %K Slow = A-periods SMA of %K Fast
 %D Slow = B-periods SMA of %K Slow

=head2  possibly helpful information:

 %K Fast corresponds to STO/1, %D Fast to STO/2, %K Slow to STO/3
 and %D Slow to STO/4

 %K Slow may also be known as the stochastic oscillator
 %D Slow is also known as the signal line
 
=head2  arguments and defaults for STO

STO accepts 7 arguments, the defaults are, in order:
5, 3, 3, 3, {I:Prices HIGH}, {I:Prices LOW}, {I:Prices CLOSE}

 The first argument is the Period n used in the formula above and for
 each of the subsequent SMA periods.

 The second argument is M-periods, the third is A-periods, fourth is B-periods.

 
By default the data used is price, which can be changed by specifying
different indicators. the order is High(n), Low(n), Last in the %K Fast
formula above.

Note that Metastock calculates the slowing via a sum of the last M-periods, 
rather than a SMA. Metastock displays %K Slow and %D Slow.

=head2 Examples

Finance::GeniusTrader::Indicators::STO->new()
Finance::GeniusTrader::Indicators::STO->new([14, 3, 3, 3])

=head2 Links

http://www.stockcharts.com/education/What/IndicatorAnalysis/indic_stochasticOscillator.html
http://www.equis.com/free/taaz/stochasticosc.html

=cut

sub initialize {
    my $self = shift;
    
    # We need to call MIN and MAX first
    $self->{'min'} = Finance::GeniusTrader::Indicators::Generic::MinInPeriod->new([ $self->{'args'}->get_arg_names(1), 
								 $self->{'args'}->get_arg_names(6)  ]);
    $self->{'max'} = Finance::GeniusTrader::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_names(1), 
								 $self->{'args'}->get_arg_names(5)  ]);

    # Initialize %D Fast
    $self->{'%d_fast'} = Finance::GeniusTrader::Indicators::SMA->new([ $self->{'args'}->get_arg_names(2), 
			    "{I:Generic:ByName " . $self->get_name(0) . "}" ]);

    # Initialize %K Slow
    $self->{'%k_slow'} = Finance::GeniusTrader::Indicators::SMA->new([ $self->{'args'}->get_arg_names(3), 
			    "{I:Generic:ByName " . $self->get_name(0) . "}" ]);

    # Initialize %D Slow
    $self->{'%d_slow'} = Finance::GeniusTrader::Indicators::SMA->new([ $self->{'args'}->get_arg_names(4),
			    "{I:Generic:ByName " . $self->{'%k_slow'}->get_name(0) . "}" ]);

    # Now add dependencies
    my $nb_days = ($self->{'args'}->get_arg_constant(2) > $self->{'args'}->get_arg_constant(3)+$self->{'args'}->get_arg_constant(4)) ? 
     $self->{'args'}->get_arg_constant(2) : $self->{'args'}->get_arg_constant(3)+$self->{'args'}->get_arg_constant(4);
    $self->add_indicator_dependency($self->{'min'}, $nb_days);
    $self->add_indicator_dependency($self->{'max'}, $nb_days);
    $self->add_arg_dependency(7, $nb_days + $self->{'args'}->get_arg_constant(1) - 1);

}

=pod

=head2 Finance::GeniusTrader::Indicators::STO::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $min_name = $self->{'min'}->get_name;
    my $max_name = $self->{'max'}->get_name;
    my $k_fast_name = $self->get_name(0);
    my $d_fast_name = $self->get_name(1);
    my $k_slow_name = $self->get_name(2);
    my $d_slow_name = $self->get_name(3);
    
    return if ($indic->is_available($k_fast_name, $i) &&
	       $indic->is_available($d_fast_name, $i) &&
	       $indic->is_available($k_slow_name, $i) &&
	       $indic->is_available($d_slow_name, $i));

    my $nb_days = ($self->{'args'}->get_arg_values($calc, $i, 2) > $self->{'args'}->get_arg_values($calc, $i, 3)+$self->{'args'}->get_arg_values($calc, $i, 4)) ? 
      $self->{'args'}->get_arg_values($calc, $i, 2) : $self->{'args'}->get_arg_values($calc, $i, 3)+$self->{'args'}->get_arg_values($calc, $i, 4);

    return if (! $self->check_dependencies($calc, $i));

    # Calculate %K Fast
    for (my $n = 0; $n < $nb_days; $n++) {

	# Return if %K Fast is available
	next if $indic->is_available($k_fast_name, $i - $n);
	
	# Get MIN and MAX
	my $lowest_low = $indic->get($min_name, $i - $n);
        my $highest_high = $indic->get($max_name, $i - $n);
    
        # Calculate %K Fast
	$highest_high += 0.000001 if ($highest_high == $lowest_low);
        my $k_fast_value = 100 * (($self->{'args'}->get_arg_values($calc, $i-$n, 7) - $lowest_low) / ($highest_high - $lowest_low));

	# Return the results
	$indic->set($k_fast_name, $i - $n, $k_fast_value);
    }

    # Calculate %D Fast
    $self->{'%d_fast'}->calculate($calc, $i);

    # Calculate %K Slow
    $self->{'%k_slow'}->calculate_interval($calc, $i - $self->{'args'}->get_arg_values($calc, $i, 4) + 1, $i);
    
    # Calculate %D Slow
    $self->{'%d_slow'}->calculate($calc, $i);

    # Get all values
    my $d_fast_value = $indic->get($self->{'%d_fast'}->get_name, $i);
    my $k_slow_value = $indic->get($self->{'%k_slow'}->get_name, $i);
    my $d_slow_value = $indic->get($self->{'%d_slow'}->get_name, $i);

    # Return the results
    $indic->set($d_fast_name, $i, $d_fast_value);
    $indic->set($k_slow_name, $i, $k_slow_value);
    $indic->set($d_slow_name, $i, $d_slow_value);
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $min_name = $self->{'min'}->get_name;
    my $max_name = $self->{'max'}->get_name;
    my $k_fast_name = $self->get_name(0);
    my $d_fast_name = $self->get_name(1);
    my $k_slow_name = $self->get_name(2);
    my $d_slow_name = $self->get_name(3);

    return if ($indic->is_available_interval($k_fast_name, $first, $last) &&
	       $indic->is_available_interval($d_fast_name, $first, $last) &&
	       $indic->is_available_interval($k_slow_name, $first, $last) &&
	       $indic->is_available_interval($d_slow_name, $first, $last));

    my $nb_days = ($self->{'args'}->get_arg_constant(2) > $self->{'args'}->get_arg_constant(3)+$self->{'args'}->get_arg_constant(4)) ? 
      $self->{'args'}->get_arg_constant(2) : $self->{'args'}->get_arg_constant(3)+$self->{'args'}->get_arg_constant(4);

    while (! $self->check_dependencies_interval($calc, $first, $last)) {
      return if $first == $last;
      $first++;
    }


    for (my $i=$first;$i<=$last;$i++) {
      # Calculate %K Fast
      for (my $n = 0; $n < $nb_days; $n++) {

	  # Return if %K Fast is available
	  next if $indic->is_available($k_fast_name, $i - $n);

	  # Get MIN and MAX
	  my $lowest_low = $indic->get($min_name, $i - $n);
      my $highest_high = $indic->get($max_name, $i - $n);
    
      # Calculate %K Fast
	  $highest_high += 0.000001 if ($highest_high == $lowest_low);
      my $k_fast_value = 100 * (($self->{'args'}->get_arg_values($calc, $i-$n, 7) - $lowest_low) / ($highest_high - $lowest_low));

	  # Return the results
	  $indic->set($k_fast_name, $i - $n, $k_fast_value);
      }
    }

    # Calculate %D Fast
    $self->{'%d_fast'}->calculate_interval($calc, $first, $last);

    # Calculate %K Slow
    $self->{'%k_slow'}->calculate_interval($calc, $first - $self->{'args'}->get_arg_constant(4) + 1, $last);
    
    # Calculate %D Slow
    $self->{'%d_slow'}->calculate_interval($calc, $first, $last);

    for (my $i=$first;$i<=$last;$i++) {  
      # Get all values
      my $d_fast_value = $indic->get($self->{'%d_fast'}->get_name, $i);
      my $k_slow_value = $indic->get($self->{'%k_slow'}->get_name, $i);
      my $d_slow_value = $indic->get($self->{'%d_slow'}->get_name, $i);

      # Return the results
      $indic->set($d_fast_name, $i, $d_fast_value);
      $indic->set($k_slow_name, $i, $k_slow_value);
      $indic->set($d_slow_name, $i, $d_slow_value);
    }
}

1;
