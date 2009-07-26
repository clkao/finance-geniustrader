package GT::Signals::Prices::GapDown;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

# Standards-Version: 1.0

use GT::Signals;
use GT::Prices;

@ISA = qw(GT::Signals);
@NAMES = ("GapDown[#1]");
@DEFAULT_ARGS = (0);

=head1 NAME

GT::Signals::GapDown

=head1 DESCRIPTION

Gaps form when opening price movements create a blank spot on the chart.
Gaps are especially significant when accompanied by an increase of volume.

A down gap forms when a security opens below previous period's low, remains
below the previous low for the entire period and close below it.

Down gaps can form on daily, weekly or monthly charts and are generally considered bearish.

=cut

sub initialize {
    my ($self) = @_;
    
    $self->add_prices_dependency(2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $q = $calc->prices;
    my $percentage = ($self->{'args'}->get_arg_values($calc, $i, 1) / 100);

    return if ($calc->signals->is_available($self->get_name, $i));
    return if (! $self->check_dependencies($calc, $i));
	
    # A Gap Down appears when the highest price of the period
    # is below the lowest price of the previous period.
    if ( $q->at($i)->[$HIGH] < ($q->at($i-1)->[$LOW] * (1 - $percentage))) {
        $calc->signals->set($self->get_name, $i, 1);
    } else {
        $calc->signals->set($self->get_name, $i, 0);
    }
}

1;
