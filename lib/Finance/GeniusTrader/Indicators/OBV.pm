package Finance::GeniusTrader::Indicators::OBV;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("OBV");

=head1 Finance::GeniusTrader::Indicators::OBV

=head2 Overview

On Balance Volume (OBV) is a momentum indicator that relates volume price change.

On Balance Volume was developed by Joe Granville and originally presented in his book New Strategy of Daily Stock Market Timing for Maximum Profits.

=head2 Calculation

On Balance Volume is calculated by adding the day's volume to a cumulative total when the security's price closes up, and subtracting the day's volume when the security's price closes down.

If today's close is greater than yesterday's close then :
OBV = Yesterday's OBV + Today's Volume

If today's close is less than yesterday's close then :
OBV = Yesterday's OBV - Today's Volume

If today's close is equal to yesterday's close then :
OBV = Yesterday's OBV

=head2 Example

Finance::GeniusTrader::Indicators::OBV->new()

=head2 Links

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $self = { 'args' => [] };
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;

    $self->add_prices_dependency(2);
}

=head2 Finance::GeniusTrader::Indicators::OBV::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $obv = 0;

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $prices = $calc->prices;
    my $diff = 0;

    if ($calc->indicators->is_available($name, $i - 1)) {
       $obv = $calc->indicators->get($name, $i - 1);
       $diff = $prices->at($i)->[$LAST] - $prices->at($i - 1)->[$LAST];
       if ($diff > 0) {
	  $obv += $prices->at($i)->[$VOLUME];
       }
       if ($diff < 0) {
	  $obv -= $prices->at($i)->[$VOLUME];
       }
       $calc->indicators->set($name, $i, $obv);
    } else {
	for(my $n = 1; $n <= $i; $n++)
	{
	    $diff = $prices->at($n)->[$LAST] - $prices->at($n - 1)->[$LAST];
	    if ($diff > 0) {
	       $obv += $prices->at($n)->[$VOLUME];
	    }
	    if ($diff < 0) {
	       $obv -= $prices->at($n)->[$VOLUME];
	    }
	    $calc->indicators->set($name, $n, $obv);
	}
    }
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    # Calculate OBV for the last record
    # so that all intermediate results will be stored
    $self->calculate($calc, $last);
}

1;
