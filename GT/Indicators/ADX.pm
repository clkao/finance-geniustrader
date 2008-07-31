package GT::Indicators::ADX;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::TR;
use GT::Indicators::SMA;
use GT::Indicators::Generic::SumDownDiffs;
use GT::Indicators::Generic::SumUpDiffs;
use GT::Indicators::Generic::Sum;
use GT::Prices;
use GT::Tools qw(:math);

@ISA = qw(GT::Indicators);
@NAMES = ("ADX[#*]","+DMI[#*]","-DMI[#*]","DMI[#*]");
@DEFAULT_ARGS = (14, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::ADX - ADX

=head1 DESCRIPTION 

=head2 Overview

=head2 Calculation

=head2 Examples

GT::Indicators::ADX->new()
GT::Indicators::ADX->new([20])

=head2 Validation

This indicators is validated by the values from comdirect.de.
The stock used was the DAX (data from yahoo) at the 04.06.2003:

ADX[14]             [2003-06-04] = 19.9961 (comdirect=20.00)
+DMI[14]            [2003-06-04] = 28.9251 (comdirect=28.93)
-DMI[14]            [2003-06-04] = 21.1723 (comdirect=21.17)
DMI[14]             [2003-06-04] = 15.4754 (comdirect=15.48)

=head2 Links

=cut
sub initialize {
    my $self = shift;

    # Initilize TR (True Range)
    $self->{'tr'} = GT::Indicators::TR->new( [ $self->{'args'}->get_arg_names(2), 
					       $self->{'args'}->get_arg_names(3),
					       $self->{'args'}->get_arg_names(4) ] );

    $self->{'dm-'} = GT::Indicators::Generic::SumDownDiffs->new([ $self->{'args'}->get_arg_names(1), 
								  $self->{'args'}->get_arg_names(3) ]);
    $self->{'dm+'} = GT::Indicators::Generic::SumUpDiffs->new([ $self->{'args'}->get_arg_names(1), 
								$self->{'args'}->get_arg_names(2) ]);

    my $tr = "{I:TR " . $self->{'args'}->get_arg_names(2) . " " .
      $self->{'args'}->get_arg_names(3) . " " .
	$self->{'args'}->get_arg_names(4) . "}";
    $self->{'sumtr'} = GT::Indicators::Generic::Sum->new([$self->{'args'}->get_arg_names(1),
							  $tr]);
    $self->{'sma'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names(1), 
						"{I:Generic:ByName ". $self->get_name(3) . "}" ]);

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $adx_name = $self->get_name(0);
    my $positive_di_name = $self->get_name(1);
    my $negative_di_name = $self->get_name(2);
    my $dmi_name = $self->get_name(3);
    my $positive_di_value = 0;
    my $negative_di_value = 0;
    my $adx_value = 0;
    my $dmi_value = 0;
    
    return if ($indic->is_available($adx_name, $i) &&
	       $indic->is_available($positive_di_name, $i) &&
	       $indic->is_available($dmi_name, $i) &&
	       $indic->is_available($negative_di_name, $i));

    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency($self->{'tr'}, $period);
    $self->add_volatile_indicator_dependency($self->{'sumtr'}, $period);
    $self->add_volatile_indicator_dependency($self->{'dm+'}, $period);
    $self->add_volatile_indicator_dependency($self->{'dm-'}, $period);

    return if (! $self->check_dependencies($calc, $i));

    if ( !$indic->is_available($dmi_name, $i-$period) ) {
      $self->calculate_interval($calc, $i-$period, $i);
    }

    $positive_di_value = 100 * ( $indic->get($self->{'dm+'}->get_name, $i) /
					$indic->get($self->{'sumtr'}->get_name, $i)) 
      unless ($indic->get($self->{'sumtr'}->get_name, $i) == 0);

    $negative_di_value = 100 * ( $indic->get($self->{'dm-'}->get_name, $i) /
					$indic->get($self->{'sumtr'}->get_name, $i)) 
      unless ($indic->get($self->{'sumtr'}->get_name, $i) == 0);

    if ($positive_di_value + $negative_di_value != 0) {
    $dmi_value = 100 * abs( $positive_di_value - $negative_di_value ) /
	( $positive_di_value + $negative_di_value ) ;
    } else {
      $dmi_value = 100 * abs( $positive_di_value - $negative_di_value ) /
	( 0.000001 + $positive_di_value + $negative_di_value ) ;
    }

    $indic->set($positive_di_name, $i, $positive_di_value);
    $indic->set($negative_di_name, $i, $negative_di_value);
    $indic->set($dmi_name, $i, $dmi_value);
    $self->{'sma'}->calculate($calc, $i);

    $adx_value = $indic->get($self->{'sma'}->get_name, $i);
    $indic->set($adx_name, $i, $adx_value);

}


sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_constant(1);
    my $adx_name = $self->get_name(0);
    my $positive_di_name = $self->get_name(1);
    my $negative_di_name = $self->get_name(2);
    my $dmi_name = $self->get_name(3);
    my $dmi_total = 0;

    return if ($indic->is_available_interval($adx_name, $first, $last) &&
           $indic->is_available_interval($positive_di_name, $first, $last) &&
           $indic->is_available_interval($dmi_name, $first, $last) &&
           $indic->is_available_interval($negative_di_name, $first, $last));

    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency($self->{'sumtr'}, $period+1);
    $self->add_volatile_indicator_dependency($self->{'tr'}, $period+1);
    $self->add_volatile_indicator_dependency($self->{'dm+'}, $period+1);
    $self->add_volatile_indicator_dependency($self->{'dm-'}, $period+1);

    while (! $self->check_dependencies_interval($calc, $first, $last)) {
      return if $first == $last;
      $first++;
    }

  for (my $i=$first-$period;$i<=$last;$i++) {
    my $positive_di_value = 0;
    my $negative_di_value = 0;
    my $dmi_value = 0;

    $positive_di_value = 100 * ( $indic->get($self->{'dm+'}->get_name, $i) /
                    $indic->get($self->{'sumtr'}->get_name, $i)) 
      unless ($indic->get($self->{'sumtr'}->get_name, $i) == 0);

    $negative_di_value = 100 * ( $indic->get($self->{'dm-'}->get_name, $i) /
					$indic->get($self->{'sumtr'}->get_name, $i)) 
      unless ($indic->get($self->{'sumtr'}->get_name, $i) == 0);

    $dmi_value = 100 * abs( $positive_di_value - $negative_di_value ) /
      ( $positive_di_value + $negative_di_value );

    $indic->set($positive_di_name, $i, $positive_di_value);
    $indic->set($negative_di_name, $i, $negative_di_value);
    $indic->set($dmi_name, $i, $dmi_value);
    $dmi_total += $dmi_value;

    $self->{'sma'}->calculate($calc, $i);
    my $adx_value = $indic->get($self->{'sma'}->get_name, $i);
      $indic->set($adx_name, $i, $adx_value);

  }

}

1;
