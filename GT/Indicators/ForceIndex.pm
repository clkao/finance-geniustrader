package GT::Indicators::ForceIndex;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("ForceIndex");

=head1 GT::Indicators::ForceIndex

GT::Indicators::ForceIndex->new()

=head2 INFORMATION

The force index itself varies too much. To be of any use, you'd better
use a 2 days exponential moving average of it.

It has been invented by Alexander Elder, and it is explained in his book
"Trading for a living" ("Vivre du trading" in french).

=cut
sub initialize {
    my $self = shift;

    $self->add_prices_dependency(2);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $name = $self->get_name;
    
    return if ($indic->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $val = $prices->at($i)->[$VOLUME] * 
	($prices->at($i)->[$CLOSE] - $prices->at($i - 1)->[$CLOSE]);
    $indic->set($name, $i, $val);
}

1;
