package GT::Indicators::TR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);

@ISA = qw(GT::Indicators);
@NAMES = ("TR[#*]");
@DEFAULT_ARGS = ("{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::TR - True Range

=head1 DESCRIPTION

The True Range (TR) is designed to measure the volatility between two days.

=head2 Calculation

The True Range is defined as the greatest of the following :

- The current high less the current low.
- The absolute value of : current high less the previous close.
- The absolute value of : current low less the previous close.

=head2 Validation

The TR is not directly validated but the ATR matches the data from
comdirect.de.

=head2 Links

http://www.stockcharts.com/education/What/IndicatorAnalysis/indic_ATR.html
http://www.equis.com/free/taaz/avertrurang.html

=cut
sub initialize {
    my ($self) = @_;

    $self->add_arg_dependency(1,2);
    $self->add_arg_dependency(2,2);
    $self->add_arg_dependency(3,2);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $tr = 0;

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
  
    my $prices = $calc->prices;

    my $high = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $low = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $yesterday_close = $self->{'args'}->get_arg_values($calc, $i-1, 3);

    # A = Today's High - Today's Low
    my $a = $high - $low;

    # B = Yesterday's Close - Today's High
    my $b = abs($yesterday_close - $high);

    # C = Yesterday's Close - Today's Low
    my $c = abs($yesterday_close - $low);

    # TR = max (A, B, C)
    $tr = max($a, $b, $c);

    # Return the results
    $calc->indicators->set($name, $i, $tr);
}

1;
