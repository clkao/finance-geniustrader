package Finance::GeniusTrader::Indicators::RSquare;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# standards upgrade and major corrections Copyright 2008 Thomas Weigert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id$

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::BPCorrelation;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("RSquare[#1, #2]");
@DEFAULT_ARGS = (14, "{I:Prices CLOSE}");

=pod

=head1 Finance::GeniusTrader::Indicators::RSquare

=head2 Overview

This function calculates the R-Squared coefficient.

=head2 Calculation

Pwr(Corr(Cum(1),C,14,0),2)
 
=cut

sub initialize {
    my $self = shift;

    $self->{'correlation'} = Finance::GeniusTrader::Indicators::BPCorrelation->new([ 
                                 $self->{'args'}->get_arg_constant(1),
                                 '{I:Generic:Cum 1 }',
                                 $self->{'args'}->get_arg_names(2) ]);

    $self->add_indicator_dependency($self->{'correlation'}, 1);
    $self->add_prices_dependency(2);
}

=pod

=head2 Finance::GeniusTrader::Indicators::RSquare::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $period = $self->{'args'}->get_arg_constant(1);
    my $correlation_name = $self->{'correlation'}->get_name;
    my $name = $self->get_name;

    return if ($indic->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $correlation_value = $indic->get($correlation_name, $i);
    my $rsquare_value = $correlation_value ** 2;
    
    $indic->set($name, $i, $rsquare_value);
}

1;
