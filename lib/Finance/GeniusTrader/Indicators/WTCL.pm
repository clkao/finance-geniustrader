package GT::Indicators::WTCL;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("WTCL[#1]");
@DEFAULT_ARGS=(2, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 GT::Indicators::WTCL

=head2 Overview

The Weighted Close indicator is simply an average of each day's price. It gets its name from the fact that extra weight is given to the closing price. The Median Price and Typical Price are similar indicators.

=head2 Calculation

The Weighted Close indicator is calculated by multiplying the close by $weight, adding the high and the low to this product, and dividing by (2 + $weight). The result is the average price with extra weight given to the closing price.

=head2 Parameters

The standard Weighted Close is configured with : $weight = 2.

=head2 Links

http://www.equis.com/free/taaz/weightedclose.html
http://www.futuresource.com/industry/wtcl.asp

=cut

sub initialize {
    my ($self) = @_;
    $self->add_arg_dependency(2, 1);
    $self->add_arg_dependency(3, 1);
    $self->add_arg_dependency(4, 1);
}

=head2 GT::Indicators::WTCL::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $weight = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;
    my $prices = $calc->prices;

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Weighted Close = (Today's High + Today's Low + Today's Close * 2 ) / 4
    my $wtcl = (( $self->{'args'}->get_arg_values($calc, $i, 2) + 
		  $self->{'args'}->get_arg_values($calc, $i, 3) + 
		  $self->{'args'}->get_arg_values($calc, $i, 4) * $weight) / (2 + $weight));

    $calc->indicators->set($name, $i, $wtcl);
}

1;
