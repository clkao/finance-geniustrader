package Finance::GeniusTrader::Indicators::Generic::SumDownDiffs;

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
@NAMES = ("SumDownDiffs[#*]");
@DEFAULT_ARGS = (14, "{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::Generic::SumDownDiffs - Calculation of the Sum of the last n days when the price goes down

=head1 DESCRIPTION 

Calculates the Sum of the difference of the last n days when the price goes down. 

=head2 Overview

=head2 Calculation

=head2 Examples

Finance::GeniusTrader::Indicators::Generic::SumDownDiffs->new()

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
    my $yesterday;
    my $today;

    return if (! defined($nb));

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $nb);

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    $yesterday = $self->{'args'}->get_arg_values($calc, $i-$nb, 2);

    return if (! defined($yesterday));
    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
       $today = $self->{'args'}->get_arg_values($calc, $n, 2);
       if ($today < $yesterday ) {
	   $sum += -($today - $yesterday);
       }
       $yesterday = $today;
    }
    $calc->indicators->set($name, $i, $sum);
}

1;
