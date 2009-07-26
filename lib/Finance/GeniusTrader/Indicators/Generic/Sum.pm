package Finance::GeniusTrader::Indicators::Generic::Sum;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Tools qw(:math);
use Finance::GeniusTrader::ArgsTree;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("Sum[#*]");
@DEFAULT_ARGS = (14, "{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::Generic::Sum - Calculation of the Sum of the last n days 

=head1 DESCRIPTION 

Calculates the Sum of the last n days.

=head2 Overview

=head2 Calculation

=head2 Examples

Finance::GeniusTrader::Indicators::Generic::SumUp->new()

=head2 Links

=cut

sub initialize {
    my ($self) = @_;
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;
    my $sum = 0;
    my $today;

    return if (! defined($nb));

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $nb);

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
       $today = $self->{'args'}->get_arg_values($calc, $n, 2);
       $sum += $today;
    }
    $calc->indicators->set($name, $i, $sum);
}

1;
