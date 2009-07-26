package GT::Indicators::SMI;

# Copyright 2008 Thomas Weigert
# Based on and for GeniusTrader (C) 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

# $Id: SMI.pm,v 1.10 2008/03/08 20:16:16 ras Exp ras $

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::EMA;
use GT::Indicators::Generic::MinInPeriod;
use GT::Indicators::Generic::MaxInPeriod;
use GT::Indicators::Generic::Container;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("\%K[#1,#2,#3]","\%D[#1,#2,#3,#4]");
@DEFAULT_ARGS = (5, 3, 3, 3, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}" );

=pod

=head1 GT::Indicators::SMI

=head2 Overview

The Stochastic Momentum Index (SMI) is based on the Stochastic
Oscillator. The difference is that the Stochastic Oscillator
calculates where the close is relative to the high/low range, while
the SMI calculates where the close is relative to the midpoint of the
high/low range. The values of the SMI range from +100 to -100. When
the close is greater than the midpoint, the SMI is above zero, when
the close is less than than the midpoint, the SMI is below zero.

The SMI is interpreted the same way as the Stochastic
Oscillator. Extreme high/low SMI values indicate overbought/oversold
conditions. A buy signal is generated when the SMI rises above -50, or
when it crosses above the signal line. A sell signal is generated when
the SMI falls below +50, or when it crosses below the signal
line. Also look for divergence with the price to signal the end of a
trend or indicate a false trend.

The Stochastic Momentum Index was developed by William Blau and was
introduced in his article in the January, 1993 issue of Technical
Analysis of Stocks & Commodities magazine.

=head2 Calculation

CM = Close - ( Highest high(n) + Lowest low(n) ) / 2
CM' = EMA(EMA(CM, A), B)
HL = Highest high(n) - Lowest low(n)
HL' = EMA(EMA(HL, A), B)

%K = 100 * CM' / (HL' / 2)
%D = SMA(%K)

=head2 Restrictions

This indicator requires that the first four parameters are constant
values and will abort otherwise.


=head2 Examples

GT::Indicators::SMI->new()
GT::Indicators::SMI->new([14, 3, 3, 3])

=head2 Links

http://www.fmlabs.com/reference/default.htm?url=SMI.htm
http://trader.online.pl/MSZ/e-w-Stochastic_Momentum_Indicator.html
(note that the former incorrectly uses "-" in CM).



=cut

sub initialize {
    my $self = shift;
    
    for (my $i=1;$i<=4;$i++) {
      die "Argument $i must be a constant value.\n" unless $self->{'args'}->is_constant($i);
    }

    # Define a container for CM and HL
    $self->{'cm'} = GT::Indicators::Generic::Container->new(['CM']);
    $self->{'hl'} = GT::Indicators::Generic::Container->new(['HL']);

    
    # We need to call MIN and MAX first
    $self->{'min'} = GT::Indicators::Generic::MinInPeriod->new([ $self->{'args'}->get_arg_names(1), 
                                                                 $self->{'args'}->get_arg_names(6)  ]);
    $self->{'max'} = GT::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_names(1), 
                                                                 $self->{'args'}->get_arg_names(5)  ]);

    # Initialize smoothing of CM
    $self->{'smooth_cm'} = GT::Indicators::EMA->new([ $self->{'args'}->get_arg_names(3), "{I:EMA " . $self->{'args'}->get_arg_names(2) . "{I:Generic:Container CM }}" ]);

    # Initialize smoothing of HL
    $self->{'smooth_hl'} = GT::Indicators::EMA->new([ $self->{'args'}->get_arg_names(3), "{I:EMA " . $self->{'args'}->get_arg_names(2) . "{I:Generic:Container HL }}" ]);

    # Initialize smoothing of %K
    $self->{'%d'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names(4), "{I:Generic:ByName " . $self->get_name(0) . "}" ]);

    # Smoothing functions are args 2 and 3
    my $nb_days = $self->{'args'}->get_arg_names(2) + $self->{'args'}->get_arg_names(3) + $self->{'args'}->get_arg_names(4);

    $self->add_indicator_dependency($self->{'min'}, $nb_days);
    $self->add_indicator_dependency($self->{'max'}, $nb_days);
    $self->add_arg_dependency(7, $nb_days + $self->{'args'}->get_arg_constant(1));

    
}

=pod

=head2 GT::Indicators::SMI::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $min_name = $self->{'min'}->get_name;
    my $max_name = $self->{'max'}->get_name;
    my $k_name = $self->get_name(0);
    my $d_name = $self->get_name(1);
    my $cm_name = $self->{'cm'}->get_name;
    my $hl_name = $self->{'hl'}->get_name;
    
    return if ($indic->is_available($cm_name, $i) &&
	       $indic->is_available($hl_name, $i) &&
               $indic->is_available($k_name, $i));


    # Smoothing functions are args 2 and 3
    my $nb_days = $self->{'args'}->get_arg_values($calc, $i, 2) + $self->{'args'}->get_arg_values($calc, $i, 3) + $self->{'args'}->get_arg_values($calc, $i, 4);

    return if (! $self->check_dependencies($calc, $i));

    # Calculate CM
    for (my $n = 0; $n < $nb_days; $n++) {

	# Return if CM is available
	next if $indic->is_available($cm_name, $i - $n);
	
	# Get MIN and MAX
	my $lowest_low = $indic->get($min_name, $i - $n);
        my $highest_high = $indic->get($max_name, $i - $n);
    
        # Calculate CM
        my $cm_value = $self->{'args'}->get_arg_values($calc, $i - $n, 7) - (($highest_high + $lowest_low) / 2 );

	# Return the results
	$indic->set($cm_name, $i - $n, $cm_value);

	# Calculate HL
	my $hl_value = $highest_high - $lowest_low;

	# Return the results
	$indic->set($hl_name, $i - $n, $hl_value);

    }

    my $k_first = $i - $self->{'args'}->get_arg_values($calc, $i, 4) + 1;

    $self->{'smooth_cm'}->calculate_interval($calc, $k_first, $i);
    $self->{'smooth_hl'}->calculate_interval($calc, $k_first, $i);

    for (my $n=$k_first; $n<=$i; $n++) {
      my $s2 = $indic->get($self->{'smooth_cm'}->get_name, $n);
      my $h2 = $indic->get($self->{'smooth_hl'}->get_name, $n);
      my $k_value = 100 * $s2 / ( $h2 / 2 );
      $indic->set($k_name, $n, $k_value);
    }
    
    $self->{'%d'}->calculate($calc, $i);
    $indic->set($d_name, $i, $indic->get($self->{'%d'}->get_name, $i));

}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $min_name = $self->{'min'}->get_name;
    my $max_name = $self->{'max'}->get_name;
    my $k_name = $self->get_name(0);
    my $d_name = $self->get_name(1);
    my $cm_name = $self->{'cm'}->get_name;
    my $hl_name = $self->{'hl'}->get_name;

    return if ($indic->is_available_interval($cm_name, $first, $last) &&
	       $indic->is_available_interval($hl_name, $first, $last) &&
               $indic->is_available_interval($k_name, $first, $last));

    # Smoothing functions are args 2 and 3
    my $nb_days = $self->{'args'}->get_arg_constant(2) + $self->{'args'}->get_arg_constant(3) + $self->{'args'}->get_arg_names(4);

    while (! $self->check_dependencies_interval($calc, $first, $last)) {
      return if $first == $last;
      $first++;
    }


    for (my $i=$first-$nb_days+1;$i<=$last;$i++) {

	  # Return if CM is available
          next if $indic->is_available($cm_name, $i);

	  # Get MIN and MAX
          my $lowest_low = $indic->get($min_name, $i);
          my $highest_high = $indic->get($max_name, $i);
    
	  # Calculate CM
          my $cm_value = $self->{'args'}->get_arg_values($calc, $i, 7) - (($highest_high + $lowest_low) / 2 );

	  # Return the results
          $indic->set($cm_name, $i, $cm_value);

	  # Calculate HL
	  my $hl_value = $highest_high - $lowest_low;

	  # Return the results
          $indic->set($hl_name, $i, $hl_value);

    }

    my $k_first = $first - $self->{'args'}->get_arg_names(4) + 1;

    # Calculate smoothing
    $self->{'smooth_cm'}->calculate_interval($calc, $k_first, $last);
    $self->{'smooth_hl'}->calculate_interval($calc, $k_first, $last);

    for (my $i=$k_first;$i<=$last;$i++) {  
      my $s2 = $indic->get($self->{'smooth_cm'}->get_name, $i);
      my $h2 = $indic->get($self->{'smooth_hl'}->get_name, $i);
      my $k_value = 100 * $s2 / ( $h2 / 2 );
      $indic->set($k_name, $i, $k_value);
    }

    $self->{'%d'}->calculate_interval($calc, $first, $last);
    for (my $i=$first;$i<=$last;$i++) {  
      $indic->set($d_name, $i, $indic->get($self->{'%d'}->get_name, $i));
    }
}


1;
