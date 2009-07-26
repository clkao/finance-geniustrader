package Finance::GeniusTrader::Indicators::Generic::Divide;

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
@NAMES = ("Divide[#*]");
@DEFAULT_ARGS = ();

=head1 NAME

Finance::GeniusTrader::Indicators::Generic::Divide - Calculates Param1 / Param2

=head1 DESCRIPTION

This Indicator is calculation an division of several parameters. 

=head2 Overview

=head2 Calculation

=head2 Examples

=head2 Links

=cut

sub initialize {
    my ($self) = @_;
    for (my $j = 1; $j <= $self->{'args'}->get_nb_args; $j++) {
      unless ($self->{'args'}->is_constant($j)) {
	$self->add_arg_dependency($j, 1);
      }
    }
    
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;

    return if ($calc->indicators->is_available($self->get_name, $i));

    return if (! $self->check_dependencies($calc, $i));

    my $value = $self->{'args'}->get_arg_values($calc, $i, 1);
    return if (! defined($value) );

    my $div;
    for (my $j = 2; $j <= $self->{'args'}->get_nb_args; $j++)
    {
	$div = $self->{'args'}->get_arg_values($calc, $i, $j);
	$value /= $div unless ($div == 0);
    }
    $indic->set($self->get_name, $i, $value);
}


1;
