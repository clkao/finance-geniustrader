package Finance::GeniusTrader::Signals::Volatility::NR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Signals;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Indicators::Range;
use Finance::GeniusTrader::Indicators::Generic::MinInPeriod;

@ISA = qw(Finance::GeniusTrader::Signals);
@NAMES = ("NR[#1]");
@DEFAULT_ARGS = (7);

=head1 NAME

Finance::GeniusTrader::Signals::Volatility::NR

=head1 DESCRIPTION

NR is for Narrowest Range. It is parametered with the period length to
look at for the size of ranges.

=cut
sub initialize {
    my ($self) = @_;
    
    $self->{'range'} = Finance::GeniusTrader::Indicators::Range->new;
    $self->{'min_range'} = Finance::GeniusTrader::Indicators::Generic::MinInPeriod->new(
	    [ $self->{'args'}->get_arg_constant(1), "{I:Range}" ]);

    $self->add_indicator_dependency($self->{'range'}, $self->{'args'}->get_arg_constant(1));
    $self->add_indicator_dependency($self->{'min_range'}, 1);
    $self->add_prices_dependency(1);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $min_name = $self->{'min_range'}->get_name;
    my $range_name = $self->{'range'}->get_name;
    my $name = $self->get_name;

    return if ($calc->signals->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # If the narrowest range is the range of today 
    if ( $indic->get($min_name, $i) == $indic->get($range_name, $i) )
    {
	$calc->signals->set($name, $i, 1);
    } else {
	$calc->signals->set($name, $i, 0);
    }
}

1;
