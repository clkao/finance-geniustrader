package GT::Indicators::Generic::SumDownDiffs;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);
use GT::ArgsTree;

@ISA = qw(GT::Indicators);
@NAMES = ("SumDownDiffs[#*]");
@DEFAULT_ARGS = (14, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::Generic::SumDownDiffs - Calculation of the Sum of the last n days when the price goes down

=head1 DESCRIPTION 

Calculates the Sum of the difference of the last n days when the price goes down. 

=head2 Overview

=head2 Calculation

=head2 Examples

GT::Indicators::Generic::SumDownDiffs->new()

=head2 Links

=cut

sub initialize {
    my ($self) = @_;
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    return if ($calc->indicators->is_available($name, $i));
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $sum = 0;
    my $yesterday;
    my $today;

    return if (! defined($nb));

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $nb);

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
