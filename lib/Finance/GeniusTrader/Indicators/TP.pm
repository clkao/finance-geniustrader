package GT::Indicators::TP;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("TP[#*]");
@DEFAULT_ARGS = ("{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 GT::Indicators::TP

=head2 Overview

The Typical Price indicator provides a simple, single-line plot of the day's average price. Some investors use th Typical Price rather than the closing price when creating moving average penetration systems.

The Typical Price is a building block of the Money Flow Index.

=head2 Calculation

The Typical Price indicator is calculated by adding the high, low and closing prices together, and then dividing by three. The result is the average, or typical price.

=head2 Note

The Typical Price is sometimes called "Pivot Point".

=head2 Validation

This indicator is indirectly validatet by I:CCI.

=cut

=head2 GT::Indicators::TP::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $prices = $calc->prices;

    return if ($calc->indicators->is_available($name, $i));

    # Typical Price = (Today's High + Today's Low + Today's Close ) / 3
    my $tp = (( $self->{'args'}->get_arg_values($calc, $i, 1) + 
		$self->{'args'}->get_arg_values($calc, $i, 2) +
		$self->{'args'}->get_arg_values($calc, $i, 3) ) / 3);

    $calc->indicators->set($name, $i, $tp);

}
