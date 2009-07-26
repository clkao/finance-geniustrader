package Finance::GeniusTrader::Indicators::ADXR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

# $Id$

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::ADX;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("ADXR[#*]");
@DEFAULT_ARGS = (14, 14, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=pod

=head1 Finance::GeniusTrader::Indicators::ADXR

=head2 Overview

=head2 Calculation

ADXR = (Today's ADX + ADX #1 days ago) / 2

=head2 Examples

Finance::GeniusTrader::Indicators::ADXR->new()
Finance::GeniusTrader::Indicators::ADXR->new([20])

=head2 Links

=cut

sub initialize {
    my $self = shift;
    
    # Initilize ADX
    $self->{'adx'} = Finance::GeniusTrader::Indicators::ADX->new([ $self->{'args'}->get_arg_names(2), 
						$self->{'args'}->get_arg_names(3),
						$self->{'args'}->get_arg_names(4),
						$self->{'args'}->get_arg_names(5) ] );
}

=head2 Finance::GeniusTrader::Indicators::ADXR::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $adx_name = $self->{'adx'}->get_name;
    my $adxr_name = $self->get_name(0);
    my $adxr_value = 0;
    
    return if ($indic->is_available($adxr_name, $i));
    
    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency($self->{'adx'}, $period);

    return if (! $self->check_dependencies($calc, $i));
    return if (! $self->check_dependencies($calc, $i - $period));

    # Calculate ADXR value
    $adxr_value = ($indic->get($adx_name, $i) + $indic->get($adx_name, $i - $period)) / 2;

    # Return ADX[#1] value
    $indic->set($adxr_name, $i, $adxr_value);
    
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    # Calculate ADXR in the "reverse" way
    for (my $i = $last; $i >= $first; $i--)
    {
        $self->calculate($calc, $i);
    }

}



1;
