package Finance::GeniusTrader::Indicators::SWMA;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("SWMA[#1,#2]");
@DEFAULT_ARGS = (5, "{I:Prices CLOSE}");

=head1 Finance::GeniusTrader::Indicators::SWMA

The Sine-Weighted Moving Average (SWMA) is a moving average using a sine factor to take into account both time and price movements. Very good at catching tops and bottoms, while filtering out unnecessary noise.

=head2 Calculation

SWMA = ( Sum of (sin(n*180/6*PI/180) * Close(i)) for i = 1 to i = period ) / (Sum
of (sin(n*180/6*PI/180)) for i = 1 to i = period)

=head2 Examples

Finance::GeniusTrader::Indicators::SWMA->>new()
Finance::GeniusTrader::Indicators::SWMA->new([30, {I:Prices OPEN}])

=head2 Links

http://www.ivorix.com/en/products/tech/smooth/swma.html

=cut

sub initialize {
    my ($self) = @_;

    $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
}

=head2 Finance::GeniusTrader::Indicators::SWMA::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_constant(1);
    my $name = $self->get_name;
    my $counter = 0;
    my $numerator = 0;
    my $denominator = 0;
    
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $pi = 3.141512;
    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	$numerator += (sin(($nb - $counter) * 180 / 6 * $pi / 180) * $self->{'args'}->get_arg_values($calc, $n, 2));
	$denominator += (sin(($nb - $counter) * 180 / 6 * $pi / 180));
	$counter += 1;
    }
    my $swma = $numerator / $denominator;
    $calc->indicators->set($name, $i, $swma);
}

