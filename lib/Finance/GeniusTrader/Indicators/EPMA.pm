package Finance::GeniusTrader::Indicators::EPMA;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("EPMA[#1,#2]");
@DEFAULT_ARGS = (20, "{I:Prices CLOSE}");


=head2 Finance::GeniusTrader::Indicators::EPMA

=head2 Overview

The Endpoint Moving Average (EPMA) is focus on divergences between the original time series and the transposed time series. They may be used in
forecasting applications or as additional inputs for neural analyses.

=head2 Calculation

EPMA(n) = [2 / (n * (n + 1))] * Sum of (((3 * i) - n - 1) * Close(i)) from i = 1 to i = n

=head2 Examples

Finance::GeniusTrader::Indicators::EPMA->new()
Finance::GeniusTrader::Indicators::EPMA->new([50])
Finance::GeniusTrader::Indicators::EPMA->new([30], "OPEN", $GET_OPEN)

=head2 Links

http://www.ivorix.com/en/products/tech/smooth/epma.html

=cut

sub initialize {
    my ($self) = @_;

    $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
}
=head2 Finance::GeniusTrader::Indicators::EPMA::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_constant(1) || 20;
    my $name = $self->get_name;
    my $weight = 0;
    my $sum = 0;
    my $position = 0;
    
    return if ($calc->indicators->is_available($name, $i));
    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $nb);
    return if (! $self->check_dependencies($calc, $i));

    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	$position += 1;
	$weight = ((3 * $position) - $nb - 1) ;
	$sum += $self->{'args'}->get_arg_values($calc, $n, 2) * $weight;
    }
    my $coef = ( 2 / ($nb * ($nb + 1)));
    $calc->indicators->set($name, $i, $sum * $coef);
}

1;
