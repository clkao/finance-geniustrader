package Finance::GeniusTrader::Indicators::CHAIKIN;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::ADL;
use Finance::GeniusTrader::Indicators::EMA;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("CHAIKIN[#1,#2]");
@DEFAULT_ARGS = (3, 10);

=head2 Finance::GeniusTrader::Indicators::CHAIKIN

=head2 Overview

The Chaikin Oscillator is a moving average oscillator based on the Accumulation/Distribution indicator (ADL.pm).

=head2 Calculation

The formula is the difference between the 3-day exponential moving average and the 10-day exponential moving average of the Accumulation/Distribution Line.

=head2 Examples

Finance::GeniusTrader::Indicators::CHAIKIN->new()
Finance::GeniusTrader::Indicators::CHAIKIN->new([3, 10])

=head2 Links

http://www.stockcharts.com/education/What/IndicatorAnalysis/indic_ChaikinOscillator.html
http://www.equis.com/free/taaz/chaikinosc.html

=cut

sub initialize {
    my $self = shift;

    $self->{'ema1'} = Finance::GeniusTrader::Indicators::EMA->new([ $self->{'args'}->get_arg_names(1), "{I:ADL}"] );
    $self->{'ema2'} = Finance::GeniusTrader::Indicators::EMA->new([ $self->{'args'}->get_arg_names(2), "{I:ADL}"] );

    $self->add_indicator_dependency($self->{'ema1'}, 1);
    $self->add_indicator_dependency($self->{'ema2'}, 1);
}

=head2 Finance::GeniusTrader::Indicators::CHAIKIN::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $ema1 = $self->{'ema1'};
    my $ema2 = $self->{'ema2'};
    my $ema1_name = $ema1->get_name;
    my $ema2_name = $ema2->get_name;
    my $chaikin_name = $self->get_name(0);

    return if ($indic->is_available($chaikin_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Get both EMA value
    my $ema1_value = $indic->get($ema1_name, $i);
    my $ema2_value = $indic->get($ema2_name, $i);

    # Calculate the Chaikin Oscillator
    my $chaikin_value = $ema1_value - $ema2_value;
    
    # Return the results
    $indic->set($chaikin_name, $i, $chaikin_value);
}

1;
