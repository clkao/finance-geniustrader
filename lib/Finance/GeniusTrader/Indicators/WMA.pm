package Finance::GeniusTrader::Indicators::WMA;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("WMA[#*]");
@DEFAULT_ARGS = (20, "{I:Prices CLOSE}");

=head1 Finance::GeniusTrader::Indicators::WMA

=head2 Overview

The Weighted Moving Average (WMA) is designed to put more weight on recent data and less weight on past data. A weighted moving average is calculated by multiplying each of the previous day's data by a weight.

=head2 Calculation

WMA(5) = (1/15) * (5 * Close(i) + 4 * Close(i - 1) + 3 * Close(i - 2) + 2 * Close(i - 3) + 1 * Close(i - 4))

=head2 Examples

Finance::GeniusTrader::Indicators::WMA->new()
Finance::GeniusTrader::Indicators::WMA->new([50])
Finance::GeniusTrader::Indicators::WMA->new([30], "OPEN", $GET_OPEN)

=head2 Links

http://www.equis.com/free/taaz/movingaverages.html

=cut

sub initialize {
    my ($self) = @_;
}

=head2 Finance::GeniusTrader::Indicators::WMA::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;
    my $weight = 0;
    my $sum_of_weight = 0;
    my $sum = 0;
    
    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $nb);

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	$weight += 1;
	$sum += $self->{'args'}->get_arg_values($calc, $n, 2) * $weight;
	$sum_of_weight += $weight;
    }
    $calc->indicators->set($name, $i, $sum / $sum_of_weight);
}

1;
