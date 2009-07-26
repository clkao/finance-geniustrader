package Finance::GeniusTrader::Indicators::Generic::Speed;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Tools qw(:generic);
use Finance::GeniusTrader::Eval;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("Speed[#*]","PercentSpeed[#*]");
@DEFAULT_ARGS = ("{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::Generic::Speed - Speed of a indicator

=head1 DESCRIPTION

This function returns today's value minus yesterday's value of the indicator
given on arguments. Without indicator, the close price is used.

=cut

sub initialize {
    my ($self) = @_;

    $self->add_arg_dependency(1, 2);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    
    return if ($calc->indicators->is_available($self->get_name(0), $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $today = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $yesterday = $self->{'args'}->get_arg_values($calc, $i - 1, 1);

    $calc->indicators->set($self->get_name(0), $i, $today - $yesterday);
    if ($yesterday)
    {
	$calc->indicators->set($self->get_name(1), $i, 
		100 * ($today - $yesterday) / abs($yesterday)
	    );
    } 
}
