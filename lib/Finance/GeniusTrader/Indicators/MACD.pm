package Finance::GeniusTrader::Indicators::MACD;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::EMA;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("MACD[#1,#2,#4]","MACDSignal[#3,#4]","MACDDifference[#1,#2,#3,#4]");
@DEFAULT_ARGS = (12, 26, 9, "{I:Prices CLOSE}");

=pod

=head2 Finance::GeniusTrader::Indicators::MACD

The standard Moving Average Convergence Divergence (MACD 12-26-9) can be called like that : Finance::GeniusTrader::Indicators::MACD->new()

If you need a non standard MACD :
Finance::GeniusTrader::Indicators::MACD->new([20, 50, 15])

=cut

sub initialize {
    my $self = shift;
    
    # We need 3 EMA indicators to calculate the MACD
    $self->{'first_ema'} = Finance::GeniusTrader::Indicators::EMA->new([ $self->{'args'}->get_arg_names(1), $self->{'args'}->get_arg_names(4)]);
    $self->{'second_ema'} = Finance::GeniusTrader::Indicators::EMA->new([ $self->{'args'}->get_arg_names(2), $self->{'args'}->get_arg_names(4)]);
    my $diff = "{I:Generic:Eval {I:EMA @{[$self->{'first_ema'}->{'args'}->get_arg_names()]}} - {I:EMA @{[$self->{'second_ema'}->{'args'}->get_arg_names()]}}}";
    $self->{'third_ema'} = Finance::GeniusTrader::Indicators::EMA->new([ $self->{'args'}->get_arg_names(3), "$diff" ]);
}

=pod

=head2 Finance::GeniusTrader::Indicators::MACD::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $macd_name = $self->get_name(0);
    my $signal_name = $self->get_name(1);
    my $diff_name = $self->get_name(2);
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 2);

    return if ( !defined($nb) );

    return if ($indic->is_available($macd_name, $i) &&
	       $indic->is_available($signal_name, $i) &&
	       $indic->is_available($diff_name, $i));

    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency( $self->{'first_ema'}, $nb);
    $self->add_volatile_indicator_dependency( $self->{'second_ema'}, $nb);
    $self->add_volatile_indicator_dependency( $self->{'third_ema'}, 1);

    return if (! $self->check_dependencies($calc, $i));

    # Get the EMA values and calculate and stores the MACD values
    my $first_ema_value = $indic->get($self->{'first_ema'}->get_name, $i);
    my $second_ema_value = $indic->get($self->{'second_ema'}->get_name, $i);

    #No need to calculate the 3rd EMA here, check_dependecies does it for us
    #$self->{'third_ema'}->calculate($calc, $i);
    my $third_ema_value = $indic->get($self->{'third_ema'}->get_name, $i);

    my $macd = $first_ema_value - $second_ema_value;
    my $signal = $third_ema_value;
    my $diff = $macd - $signal;

    $indic->set($macd_name, $i, $macd);
    $indic->set($signal_name, $i, $signal);
    $indic->set($diff_name, $i, $diff);
}

=pod

=head2 Finance::GeniusTrader::Indicators::MACD::calculate_interval($calc, $first, $last)

=cut

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $indic = $calc->indicators;
    my $macd_name = $self->get_name(0);
    my $signal_name = $self->get_name(1);
    my $diff_name = $self->get_name(2);
    my $nb = $self->{'args'}->get_arg_constant(2);
	my $first_ema_name = $self->{'first_ema'}->get_name(0);
	my $second_ema_name = $self->{'second_ema'}->get_name(0);
	my $third_ema_name = $self->{'third_ema'}->get_name(0);

   ($first, $last) = $self->update_interval($calc, $first, $last);

    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency( $self->{'first_ema'}, $nb);
    $self->add_volatile_indicator_dependency( $self->{'second_ema'}, $nb);
    $self->add_volatile_indicator_dependency( $self->{'third_ema'}, 1);

    while (! $self->check_dependencies_interval($calc, $first, $last)) {
      return if $first == $last;
      $first++;
    }
    return if ( !defined($nb) );

  for (my $i=$first;$i<=$last;$i++) {

    return if (defined($indic->{'values'}{$macd_name}[$i]) ? 1 : 0 &&
               defined($indic->{'values'}{$signal_name}[$i]) ? 1 : 0 &&
               defined($indic->{'values'}{$diff_name}[$i]) ? 1 : 0);

    # Get the EMA values and calculate and stores the MACD values
    my $first_ema_value = $indic->get($first_ema_name, $i);
    my $second_ema_value = $indic->get($second_ema_name, $i);

     #No need to calculate the 3rd EMA here, check_dependecies does it for us
    #$self->{'third_ema'}->calculate($calc, $i);
    my $third_ema_value = $indic->get($third_ema_name, $i);

    my $macd = $first_ema_value - $second_ema_value;
    my $signal = $third_ema_value;
    my $diff = $macd - $signal;

    $indic->set($macd_name, $i, $macd);
    $indic->set($signal_name, $i, $signal);
    $indic->set($diff_name, $i, $diff);
}
}

1;
