package GT::Indicators::BBO;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);
use GT::ArgsTree;
use GT::Indicators::BOL;

@ISA = qw(GT::Indicators);
@NAMES = ("BBO[#*]");
@DEFAULT_ARGS = (20,2,"{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::BBO - %B - the Bollinger Band Oscillator

=head1 DESCRIPTION 

Bollinger Calculated this oscillator. The %B falls below 0 if the
Price crosses the lower Band. It is set to > 1 if the price raises
above the upper band.

=head2 Parameters

The parameters are identical with those of the BOL-Indicator.

=cut


sub initialize {
    my $self = shift;
    $self->{'bol'} = GT::Indicators::BOL->new( [ $self->{'args'}->get_arg_names() ]);
    $self->add_indicator_dependency($self->{'bol'}, 1);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $bolup = $self->{'bol'}->get_name(1);
    my $bollow = $self->{'bol'}->get_name(2);

    my $val = $self->{'args'}->get_arg_values($calc, $i, 3);
    my $name = $self->get_name();

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i) );

    my $pos = 0;
    $pos = ( $val - $indic->get($bollow,$i) ) / 
      ( $indic->get($bolup, $i) - $indic->get($bollow, $i) ) 
	unless ($indic->get($bolup, $i) - $indic->get($bollow, $i)  == 0);

    $indic->set($name, $i, $pos);
}

1;
