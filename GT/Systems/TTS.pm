package GT::Systems::TTS;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Prices;
use GT::Systems;
use GT::Indicators::Generic::MinInPeriod;
use GT::Indicators::Generic::MaxInPeriod;

@ISA = qw(GT::Systems);
@NAMES = ("TTS[#1, #2]");

=head1 Turtle Trading System (TTS)

=head2 Overview

The Turtle Trading System is a very simple and very easy to understand.

It's an Asymetric Channel Breakout :

* Enter long above the highest high of the previous X days and exit with a
stop based on the lowest low of the Y previous days with Y < X

* Enter short below the lowest low of the previous W days and exit with a
stop based on the highest high of the Z previous days with Z < W


Parameters

Y = length of channel for longs
W = length of channel for shorts
=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [ 55, 20 ] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;

    $self->{'max'} = GT::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}[0], "{I:Prices HIGH}"]);
    $self->{'min'} = GT::Indicators::Generic::MinInPeriod->new([ $self->{'args'}[1], "{I:Prices LOW}"]);

    $self->add_indicator_dependency($self->{'min'}, 2);
    $self->add_indicator_dependency($self->{'max'}, 2);
    $self->add_prices_dependency($self->{'args'}[0] + 1);
    $self->add_prices_dependency($self->{'args'}[1] + 1);
}

sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;
    $self->{'max'}->calculate_interval($calc, $first, $last);
    $self->{'min'}->calculate_interval($calc, $first, $last);

    return;
}

sub long_signal {
    my ($self, $calc, $i) = @_;
    
    return 0 if (! $self->check_dependencies($calc, $i));
    
    if ( ( $calc->prices->at($i)->[$CLOSE] > 
	   $calc->indicators->get($self->{'max'}->get_name, $i - 1) )
       )
    {
	return 1;
    }
    return 0;
}

sub short_signal {
    my ($self, $calc, $i) = @_;
    
    return 0 if (! $self->check_dependencies($calc, $i));

    if ( ( $calc->prices->at($i)->[$CLOSE] < 
	   $calc->indicators->get($self->{'min'}->get_name, $i - 1) )
       )
    {
	return 1;
    }
    return 0;
}

1;
