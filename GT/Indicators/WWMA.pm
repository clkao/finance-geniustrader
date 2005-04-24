package GT::Indicators::WWMA;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("WWMA[#1]");
@DEFAULT_ARGS = (20, "{I:Prices CLOSE}");

=head1 GT::Indicators::WWMA

Welles Wilder Moving Average (WWMA) is a modified verson of the EMA.

=head2 Calculation

WWMA(i) = (1/n) * Close(i) + (1 - 1/n) * WWMA(i-1)

=head2 Examples

GT::Indicators::WWMA->new()
GT::Indicators::WWMA->new([15])
GT::Indicators::WWMA->new([30], "OPEN", $GET_OPEN)

=head2 Links

TODO

=cut

sub initialize {
    my ($self) = @_;
}

=head2 GT::Indicators::WWMA::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;
    my $wwma = 0;
    
    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $nb);

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    $wwma = $self->{'args'}->get_arg_values($calc, $i - $nb + 1, 2);
    for(my $n = $i - $nb + 2; $n <= $i; $n++) 
    {
       $wwma *= (1 - (1 / $nb));
       $wwma += ((1 / $nb) * $self->{'args'}->get_arg_values($calc, $n, 2));
    }
    $calc->indicators->set($name, $i, $wwma);
}

1;
