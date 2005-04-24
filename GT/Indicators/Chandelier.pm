package GT::Indicators::Chandelier;

# Copyright 2000-2003 Raphaël Hertzog, Fabien Fulhaber, Oliver Bossert, Joerg Sauer
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::Generic::MinInPeriod;
use GT::Indicators::Generic::MaxInPeriod;
use GT::Indicators::ATR;

@ISA = qw(GT::Indicators);
@NAMES = ("ChanUp[#*]","ChanDn[#*]");
@DEFAULT_ARGS = (22, 3);

=pod

=head2 GT::Indicators::Chandelier

The Chandelier Exit is described in Dr. Alexander Elder's Book "Come into my Trading Room" and provides
stops for closing long or short positions. It was originally conceived by Chuck LeBeau.

It accepts the number of bars to use for the calculation and a coefficient as parameters with 22 and 3 being the defaults that
are also used in the examples in the book.

ChanUp should be used for long positions, ChanDn for short positions.

=cut

sub initialize {
    my $self = shift;

    $self->{'min'} = GT::Indicators::Generic::MinInPeriod->new([ $self->{'args'}->get_arg_constant(1), 
						"{I:Prices LOW}" ]);
    $self->{'max'} = GT::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_constant(1), 
						"{I:Prices HIGH}" ]);
	$self->{'atr'} = GT::Indicators::ATR->new([ $self->{'args'}->get_arg_names(1) ]);
    
	$self->add_indicator_dependency($self->{'min'}, 1);
	$self->add_indicator_dependency($self->{'max'}, 1);
	$self->add_indicator_dependency($self->{'atr'}, 1);
}

=head2 GT::Indicators::Chandelier::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
	my $coeff = $self->{'args'}->get_arg_values($calc, $i, 2);	
	my $min = $self->{'min'};
    my $max = $self->{'max'};    
	my $atr = $self->{'atr'};    
    my $chanup_name = $self->get_name(0);
    my $chandn_name = $self->get_name(1);    

    return if ($indic->is_available($chanup_name, $i) &&
	       $indic->is_available($chandn_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $min_value = $indic->get($min->get_name, $i);
	my $max_value = $indic->get($max->get_name, $i);
	my $atr_value = $indic->get($atr->get_name, $i);	    
    
    my $chanup_value = $max_value - $coeff * $atr_value;
	my $chandn_value = $min_value + $coeff * $atr_value;    
    
    $indic->set($chanup_name, $i, $chanup_value);
    $indic->set($chandn_name, $i, $chandn_value);
}

1;

