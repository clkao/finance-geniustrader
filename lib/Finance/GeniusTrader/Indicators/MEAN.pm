package Finance::GeniusTrader::Indicators::MEAN;

# Copyright 2008 Karsten Wippler
# Based on and for GeniusTrader (C) 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id: MEAN.pm,v 1.1 2008/03/14 16:53:45 ras Exp $

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("MEAN[#1,#2]");
@DEFAULT_ARGS=("{I:Prices HIGH}", "{I:Prices LOW}");

=head1 Finance::GeniusTrader::Indicators::MEAN

=head2 Overview

The mean indicator is simply an average of each days high and low. 

=head2 Calculation

mean =(high+low)/2

=head2 Links

=cut

sub initialize {
    my ($self) = @_;
    $self->add_arg_dependency(1, 1);
    $self->add_arg_dependency(2, 1);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $prices = $calc->prices;

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $mean = (( $self->{'args'}->get_arg_values($calc, $i, 1) + 
		  $self->{'args'}->get_arg_values($calc, $i, 2) ) 
		   /2 );

    $calc->indicators->set($name, $i, $mean);
}

1;
