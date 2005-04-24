package GT::Indicators::ElderRay;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Indicators::EMA;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("BullPower[#1]", "BearPower[#1]");

=head1 GT::Indicators::ElderRay

GT::Indicators::ElderRay->new([13])

=head2 INFORMATION

It has been invented by Alexander Elder, and it is explained in his book
"Trading for a living" ("Vivre du trading" in french).

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args) = @_;
    my $self = { 'args' => defined($args) ? $args : [13] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my $self = shift;

    $self->{'mme'} = GT::Indicators::EMA->new([$self->{'args'}[0]]);
    $self->add_indicator_dependency($self->{'mme'}, 1);
    $self->add_prices_dependency(1);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $name = $self->get_name;
    
    return if ($indic->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $bull = $prices->at($i)->[$HIGH] - 
	       $indic->get($self->{'mme'}->get_name, $i);
    my $bear = $prices->at($i)->[$LOW] - 
	       $indic->get($self->{'mme'}->get_name, $i);
    $indic->set($self->get_name(0), $i, $bull);
    $indic->set($self->get_name(1), $i, $bear);
}

1;
