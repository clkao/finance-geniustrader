package GT::Indicators::BOL;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::SMA;
use GT::Indicators::StandardDeviation;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("BOL[#1,#3]","BOLSup[#1,#2,#3]","BOLInf[#1,#2,#3]");
@DEFAULT_ARGS = (20, 2, "{I:Prices CLOSE}");

=head2 GT::Indicators::BOL

Bollinger Bands are similar to moving average envelopes. The difference between Bollinger Bands and envelopes is envelopes are plotted at a fixed percentage above and below a moving average, whereas Bollinger Bands are plotted at standard deviation levels above and below a moving average.

The standard Bolling Bands (BOL 20-2) can be called like that : GT::Indicators::BOL->new()

If you need a non standard BOL :
GT::Indicators::BOL->new([25, 2.5])

=cut

sub initialize {
    my ($self) = @_;

    if ($self->{'args'}->is_constant(1)) {
        $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
    }

    $self->{'sma'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names(1),
        $self->{'args'}->get_arg_names(3) ]);
    $self->{'sd'} = GT::Indicators::StandardDeviation->new([ $self->{'args'}->get_arg_names(1),
        $self->{'args'}->get_arg_names(3) ]);

    if ($self->{'args'}->is_constant(1)) {
        $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
	$self->add_indicator_dependency($self->{'sma'}, 1);
	$self->add_indicator_dependency($self->{'sd'}, 1);
    }
}

=head2 GT::Indicators::BOL::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $nsd = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $sma = $self->{'sma'};
    my $sma_name = $sma->get_name;
    my $sd = $self->{'sd'};
    my $sd_name = $sd->get_name;
    my $bol_name = $self->get_name(0);
    my $bolsup_name = $self->get_name(1);
    my $bolinf_name = $self->get_name(2);

    return if ($indic->is_available($bol_name, $i) &&
	       $indic->is_available($bolsup_name, $i) &&
	       $indic->is_available($bolinf_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Get SMA value
    my $sma_value = $indic->get($sma_name, $i);

    # Get Standard Deviation value
    my $sd_value = $indic->get($sd_name, $i);
    
    # Bollinger Band Sup is equal to the value of the moving average + standard deviation
    my $bolsup_value = $sma_value + ($nsd * $sd_value);
    
    # Bollinger Band Inf is equal to the value of the moving average - standard deviation
    my $bolinf_value = $sma_value - ($nsd * $sd_value);
    
    # Return the results
    $indic->set($bol_name, $i, $sma_value);
    $indic->set($bolsup_name, $i, $bolsup_value);
    $indic->set($bolinf_name, $i, $bolinf_value);
}

1;
