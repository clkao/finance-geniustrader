package GT::Indicators::QSTICK;

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
@NAMES = ("QSTICK[#*]");
@DEFAULT_ARGS = (10, "{I:Prices CLOSE}", "{I:Prices OPEN}");

=head1 GT::Indicators::QSTICK

=head2 Overview

The QStick indicator was designed by Tushar Chandle to quantify candelsticks.

The distance between opening and closing prices, as known as the size of the candelstick's body, is the heart of candelsticks studies. The QStick indicator is a simple moving average of theses distances.

=head2 Interpretation

QStick values below zero show that there is a majority of black candelsticks, so that the stock is under pressure.
QStick values upper zero show that there is a majority of white candelsticks, so that the stock is going up.

=head2 Note

I don't really like the terms 'majority of black candelsticks' and 'majority of white candelsticks', i prefer to talk about 'negative volatility' and 'positive volatility'. Moreover, it might be more usefull to calculate the QStick with the percentage deviation corrected by the standard deviation instead of the absolute deviation, in order to compares qstick values or to think about levels crossover.

=head2 Calculation

QStick Indicator = A-day simple moving average (SMA) of (Close - Open)

=head2 Examples

GT::Indicators::QSTICK->new()
GT::Indicators::QSTICK->new([20])

=head2 Links

http://www.metastock.fr/QSTICK.htm

=cut

sub initialize {
    my $self = shift;
    
    my $eval = "{I:Generic:Eval " . $self->{'args'}->get_arg_names(2) . " - " .
      $self->{'args'}->get_arg_names(3) . "}";

    # Initialize the simple moving average (SMA) of (Close - Open)
    $self->{'qstick'} = GT::Indicators::SMA->new( [$self->{'args'}->get_arg_names(1), $eval] );

    $self->add_indicator_dependency($self->{'qstick'}, 1);
}

=head2 GT::Indicators::QSTICK::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $qstick_name = $self->{'qstick'}->get_name;
    my $qstick_indicator_name = $self->get_name(0);
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    
    return if ($indic->is_available($qstick_indicator_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Get QStick value
    my $qstick_value = $indic->get($qstick_name, $i);
    
    # Return the results
    $indic->set($qstick_indicator_name, $i, $qstick_value);
}

1;
