package GT::Indicators::StandardDeviation;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::SMA;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("StandardDeviation[#*]");
@DEFAULT_ARGS = (20, "{I:Prices CLOSE}");

=pod

=head1 GT::Indicators::StandardDeviation

=head2 Overview

Standard Deviation is a statistical measure of volatility. Standard Deviation is typically used as a component of other indicators, rather than as a stand-alone indicator. For example, Bollinger Bands are calculated by adding a security's Standard Deviation to a moving average.

=head2 Interpretation

High Standard Deviation values occur when the data item being analyzed (e.g., prices or an indicator) is changing dramatically. Similarly, low Standard Deviation values occur when prices are stable.

Many analysts feel that major tops are accompanied with high volatility as investors struggle with both euphoria and fear. Major bottoms are expected to be calmer as investors have few expectations of profits.

=head2 Links

http://www.equis.com/free/taaz/standardevia.html

=cut

sub initialize {
    my $self = shift;

    $self->{'sma'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names() ]);

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $sma_name = $self->{'sma'}->get_name;
    my $sd_name = $self->get_name(0);
    my $sum = 0;
    my $sd_value = 0;

    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency( $self->{'sma'}, $period );
    $self->add_volatile_arg_dependency( 2, $period );

    return if ($indic->is_available($sd_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Get the SMA value
    my $sma_value = $indic->get($sma_name, $i);

    # Calculate the Standard Deviation
    for (my $n = 0; $n < $period; $n++) {
        $sum += ( $self->{'args'}->get_arg_values($calc, ($i-$n), 2) - $sma_value )**2;
    }
    $sd_value = sqrt($sum/$period);
    
    # Return the results
    $indic->set($sd_name, $i, $sd_value);
}

1;
