package GT::Indicators::Generic::Cum;

# Copyright 2008 Thomas Weigert
# Based on and for GeniusTrader (C) 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id: Cum.pm,v 1.3 2008/03/13 05:29:59 ras Exp ras $

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
#use GT::Indicators::BPCorrelation;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("Cum[#1]");
@DEFAULT_ARGS = ("{I:Prices CLOSE}");

=pod

=head1 GT::Indicators::Generic::Cum

=head2 Overview

This function keeps a running total of its input. Each period is calculated,
it adds the current value of the input to the previous total. For example,
  {I:Generic:Cum 1}
will keep adding 1 for each period of time loaded. In effect, this counts
how many records are currently loaded.

=cut

=pod

=head2 GT::Indicators::Generic::Cum::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $name = $self->get_name;

    return if ($indic->is_available($name, $i));

    my $value;

    if ($indic->is_available($name, $i - 1)) {
      $value = $indic->get($name, $i - 1) + $self->{'args'}->get_arg_values($calc, $i, 1);
    } else {
      $value = $self->{'args'}->get_arg_values($calc, $i, 1);
    }
    
    $indic->set($name, $i, $value);
}

1;
