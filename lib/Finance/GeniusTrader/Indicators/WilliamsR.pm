package Finance::GeniusTrader::Indicators::WilliamsR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::Generic::MinInPeriod;
use Finance::GeniusTrader::Indicators::Generic::MaxInPeriod;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("WilliamsPercentR[#1]");
@DEFAULT_ARGS = (14, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 Finance::GeniusTrader::Indicators::WilliamsR

=head2 Overview

Williams %R is a momentum indicator developed by Larry Williams that
measures overbought/oversold levels.

=head2 Calculation

The formula used to calculate Williams' %R is similar to the Stochastic
Oscillator :

Williams %R = - 100 * ((Highest High (n) - Close) / (Highest High (n) - Lowest Low (n)))

=head2 Parameters

The standard Williams %R works with a 14-days parameter : n = 14

=head2 Validation

This Indicator was validated by the data available from comdirect.de: 
The DAX at 04.06.2003 (data from yahoo.com) had a Williams %R of -5.99.
This is consistent with this indicator: -5.99328026152501

=head2 Links

http://www.equis.com/free/taaz/williamspercr.html

=cut

sub initialize {
    my $self = shift;

    $self->{'min'} = Finance::GeniusTrader::Indicators::Generic::MinInPeriod->new([ $self->{'args'}->get_arg_names(1),
								 $self->{'args'}->get_arg_names(3) ] );
    $self->{'max'} = Finance::GeniusTrader::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_names(1),
								 $self->{'args'}->get_arg_names(2)] );

    $self->add_indicator_dependency($self->{'min'}, 1);
    $self->add_indicator_dependency($self->{'max'}, 1);
}

=head2 Finance::GeniusTrader::Indicators::Williams%R::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $min_name = $self->{'min'}->get_name;
    my $max_name = $self->{'max'}->get_name;
    my $name = $self->get_name(0);

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(4, 1);
    return if (! $self->check_dependencies($calc, $i));

    return if ($indic->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Get MIN and MAX values
    my $min = $indic->get($min_name, $i);
    my $max = $indic->get($max_name, $i);

    # Calculate Williams % R
    my $williams_percent_r = - 100 * (($max - $self->{'args'}->get_arg_values($calc, $i, 4)) / ($max - $min));
    
    # And return the result
    $indic->set($name, $i, $williams_percent_r);
}

1;
