package GT::Indicators::ATR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::SMA;
use GT::Indicators::TR;

@ISA = qw(GT::Indicators);
@NAMES = ("ATR[#*]");
@DEFAULT_ARGS = (14, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 GT::Indicators::ATR

=head2 Overview

The Average True Index (ATR) is a measure of volatility. High ATR values often occur at market bottom following a 'panic' sell-off.
Low ATR values are often found during extended sideways periods, such as those found at tops and after consolidation periods.

=head2 Calculation

The Average True Index is a moving average of the True Ranges.

=head2 Parameters

The standard ATR works with a fourteen-day parameter : n = 14

=head2 Example

GT::Indicators::ATR->new()
GT::Indicators::ATR->new([12])

=head2 Note

The Average True Range can be interpreted using the same techniques that are used with other volatility indicators.

=head2 Validation

This indicators is validated by the values from comdirect.de.
The stock used was the DAX (data from yahoo) at the 04.06.2003:

ATR[14]             [2003-06-04] = 79.2343 (comdirect=79.23)

=head2 Links

http://www.equis.com/free/taaz/avertrurang.html
http://stockcharts.com/education/What/IndicatorAnalysis/indic_ATR.html
http://www.finance-net.com/apprendre/techniques/atr.phtml

=cut

sub initialize {
    my $self = shift;

    my $tr = "{I:TR " . $self->{'args'}->get_arg_names(2) . " " .
      $self->{'args'}->get_arg_names(3) . " " .
	$self->{'args'}->get_arg_names(4) . "}";
    $self->{'sma'} = GT::Indicators::SMA->new([$self->{'args'}->get_arg_names(1), $tr ]);
    $self->add_indicator_dependency($self->{'sma'}, 1);
}

=head2 GT::Indicators::ATR::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $sma_name = $self->{'sma'}->get_name;
    my $atr_name = $self->get_name(0);

    return if ($indic->is_available($atr_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # Get the Average True Range
    my $atr_value = $indic->get($sma_name, $i);
    
    # Return the result
    $indic->set($atr_name, $i, $atr_value);

}

1;
