package Finance::GeniusTrader::Indicators::MaxDrawDown;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# standards upgrade Copyright 2005 Thomas Weigert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id$

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("MaxDrawDown[#1]");
@DEFAULT_ARGS = ("{I:Prices CLOSE}");

=pod

=head1 Finance::GeniusTrader::Indicators::MaxDrawDown

=head2 Overview

Calculate the MaxDrawDown, which is the worst percentage loss after reaching a maximum.

=cut

sub initialize {
    my ($self) = @_;

    $self->add_prices_dependency(2);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $current_draw_down = 0;
    my $max_draw_down = 0;
    
    return if (! $self->check_dependencies($calc, $i));

    my $high = $self->{'args'}->get_arg_values($calc, 0, 1);
    
    for (my $n = 0; $n <= $i; $n++) {
	
        if ($self->{'args'}->get_arg_values($calc, $n, 1) > $high) {
            $high = $self->{'args'}->get_arg_values($calc, $n, 1);
	} else {
            $current_draw_down = ($high - $self->{'args'}->get_arg_values($calc, $n, 1)) * 100 / $high;
	}
	if ($current_draw_down > $max_draw_down) {
	    $max_draw_down = $current_draw_down;
	}
	
    }
    $calc->indicators()->set($name, $i, $max_draw_down);
}

1;
