package GT::Indicators::RSquare;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Indicators::BPCorrelation;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("RSquare[#1]");

=pod

=head1 GT::Indicators::RSquare

=head2 Overview

This function calculates the R-Squared coefficient.

=head2 Calculation

Pwr(Corr(Cum(1),C,14,0),2)
 
=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args) = @_;
    my $self = { 'args' => defined($args) ? $args : [ 14 ] };

    $args->[0] = 14 if (! defined($args->[0]));
       
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my $self = shift;

    $self->{'correlation'} = GT::Indicators::BPCorrelation->new([ $self->{'args'}[0] ], "i,Close", sub { return $_[1] + 1 }, sub { return $_[0]->prices->at($_[1])->[$LAST] } );

    $self->add_indicator_dependency($self->{'correlation'}, 1);
    $self->add_prices_dependency(2);
}

=pod

=head2 GT::Indicators::RSquare::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $period = $self->{'args'}[0];
    my $correlation_name = $self->{'correlation'}->get_name;
    my $name = $self->get_name;

    return if ($indic->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $correlation_value = $indic->get($correlation_name, $i);
    my $rsquare_value = $correlation_value ** 2;
    
    $indic->set($name, $i, $rsquare_value);
}

1;
