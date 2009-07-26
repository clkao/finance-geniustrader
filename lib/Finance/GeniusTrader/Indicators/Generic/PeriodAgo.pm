package GT::Indicators::Generic::PeriodAgo;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:generic);

@ISA = qw(GT::Indicators);
@NAMES = ("PeriodAgo[#*]");
@DEFAULT_ARGS = (1, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::Generic::PeriodAgo - Return data from some periods ago

=head1 DESCRIPTION

This function returns N-Period Ago value of the indicator given on
arguments. Without indicator, the close price is used.

=head1 EXAMPLES

The high of 3 days ago :

 I:Generic:PeriodAgo 3 {I:Prices HIGH}

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;
    
    return if ($calc->indicators->is_available($name, $i));
    
    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $period);
    
    return if (! $self->check_dependencies($calc, $i));
    
    my $value = $self->{'args'}->get_arg_values($calc, $i - $period, 2); 
    $calc->indicators->set($name, $i, $value);
}

1;
