package GT::Indicators::TETHER;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::Generic::MinInPeriod;
use GT::Indicators::Generic::MaxInPeriod;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("TETHER[#1]");
@DEFAULT_ARGS = (50);

=head1 NAME

GT::Indicators::TETHER - Tether Line

=head1 DESCRIPTION

The Tether Line is one of the three indicators used in Trend Following System (TFS), designed by Bryan Strain.

=head1 CALCULATION

Tether Line = (Highest High (n) + Lowest Low (n)) / 2

=head1 PARAMETERS

The standard Tether Line works with a 50-day parameter : n = 50

=head1 EXAMPLE

GT::Indicators::TETHER->new()
GT::Indicators::TETHER->new([30])

=cut
sub initialize {
    my $self = shift;

    $self->{'min'} = GT::Indicators::Generic::MinInPeriod->new([ $self->{'args'}->get_arg_names(1), "{I:Prices LOW}" ]);
    $self->{'max'} = GT::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_names(1), "{I:Prices HIGH}" ]);

    $self->add_indicator_dependency($self->{'min'}, 1);
    $self->add_indicator_dependency($self->{'max'}, 1);
    $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
}

=head2 GT::Indicators::TETHER::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $q = $calc->prices;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $min = $self->{'min'};
    my $max = $self->{'max'};
    my $min_name = $min->get_name;
    my $max_name = $max->get_name;
    my $tether_name = $self->get_name(0);

    return if ($indic->is_available($tether_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Get MIN and MAX values
    my $min_value = $indic->get($min_name, $i);
    my $max_value = $indic->get($max_name, $i);

    # The tether line is equal to the sum of the highest high and lowest low, divided by two
    my $tether_line_value = (($min_value + $max_value) / 2);
    
    # Return the result
    $indic->set($tether_name, $i, $tether_line_value);
}

1;
