package GT::Signals::Volatility::NR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Signals;
use GT::Prices;
use GT::Indicators::Range;
use GT::Indicators::Generic::MinInPeriod;

@ISA = qw(GT::Signals);
@NAMES = ("NR[#1]");
@DEFAULT_ARGS = (7);

=head1 NAME

GT::Signals::Volatility::NR

=head1 DESCRIPTION

NR is for Narrowest Range. It is parametered with the period length to
look at for the size of ranges.

=cut
sub initialize {
    my ($self) = @_;
    
    $self->{'range'} = GT::Indicators::Range->new;
    $self->{'min_range'} = GT::Indicators::Generic::MinInPeriod->new(
	    [ $self->{'args'}->get_arg_constant(1), "{I:Range}" ]);

    $self->add_indicator_dependency($self->{'range'}, $self->{'args'}->get_arg_constant(1));
    $self->add_indicator_dependency($self->{'min_range'}, 1);
    $self->add_prices_dependency(1);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $min_name = $self->{'min_range'}->get_name;
    my $range_name = $self->{'range'}->get_name;
    my $name = $self->get_name;

    return if ($calc->signals->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # If the narrowest range is the range of today 
    if ( $indic->get($min_name, $i) == $indic->get($range_name, $i) )
    {
	$calc->signals->set($name, $i, 1);
    } else {
	$calc->signals->set($name, $i, 0);
    }
}

1;
