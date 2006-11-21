package GT::Indicators::T3;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Indicators::EMA;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("T3[#1,#2]");

=pod

=head1 GT::Indicators::T3

=head2 Overview

T3 is an excellent data-fitting technique by Tim Tillson (cf. "Smoothing
Techniques For More Accurate Signals" in Technical Analysis of Stocks and
Commodities - January 1998)

=head2 Calculation

N is the Exponential Moving Average Period
a is the amplification percentage of the filter's response to price
movement (0 < a < 1)

e1 = N-days EMA of Close Prices
e2 = N-days EMA of e1
e3 = N-days EMA of e2
e4 = N-days EMA of e3
e5 = N-days EMA of e4
e6 = N-days EMA of e5

c1 = (-a)^3
c2 = 3 * a^2
c3 = - 6 * a^2 - 3 * a - 3 * a^3
c4 = 1 + 3 * a + a^3 + 3 * a^2

T3 = c1 * e6 + c2 * e5 + c3 * e4 + c4 * e3

=head2 Parameters

The default values are :
N = 5
a = 0.7

=head2 Examples

GT::Indicators::T3->new()
GT::Indicators::T3->new([5, 0.7])

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args) = @_;
    my $self = { 'args' => defined($args) ? $args : [ 5, 0.7 ] };

    $args->[0] = 5 if (! defined($args->[0]));
    $args->[1] = 0.7 if (! defined($args->[1]));
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my $self = shift;
    
    # Initialize e1, e2, e3, e4, e5 and e6
    $self->{'e1'} = GT::Indicators::EMA->new([ $self->{'args'}[0] ]);
    
    $self->{'e2'} = GT::Indicators::EMA->new([ $self->{'args'}[0],
        "{I:EMA @{[$self->{'e1'}->{'args'}->get_arg_names()]}}" ]);

    $self->{'e3'} = GT::Indicators::EMA->new([ $self->{'args'}[0],
        "{I:EMA @{[$self->{'e2'}->{'args'}->get_arg_names()]}}" ]);

    $self->{'e4'} = GT::Indicators::EMA->new([ $self->{'args'}[0],
        "{I:EMA @{[$self->{'e3'}->{'args'}->get_arg_names()]}}" ]);

    $self->{'e5'} = GT::Indicators::EMA->new([ $self->{'args'}[0],
        "{I:EMA @{[$self->{'e4'}->{'args'}->get_arg_names()]}}" ]);

    $self->{'e6'} = GT::Indicators::EMA->new([ $self->{'args'}[0],
        "{I:EMA @{[$self->{'e5'}->{'args'}->get_arg_names()]}}" ]);

    $self->add_indicator_dependency($self->{'e1'}, $self->{'args'}[0] * 5 - 4);
    $self->add_indicator_dependency($self->{'e2'}, $self->{'args'}[0] * 4 - 3);
    $self->add_indicator_dependency($self->{'e3'}, $self->{'args'}[0] * 3 - 2);
    $self->add_indicator_dependency($self->{'e4'}, $self->{'args'}[0] * 2 - 1);
    $self->add_indicator_dependency($self->{'e5'}, $self->{'args'}[0]);
    $self->add_indicator_dependency($self->{'e6'}, 1);
}

=pod

=head2 GT::Indicators::T3::calculate($calc, $day, $args, $key, $data)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $e1_name = $self->{'e1'}->get_name;
    my $e2_name = $self->{'e2'}->get_name;
    my $e3_name = $self->{'e3'}->get_name;
    my $e4_name = $self->{'e4'}->get_name;
    my $e5_name = $self->{'e5'}->get_name;
    my $e6_name = $self->{'e6'}->get_name;
    my $t3_name = $self->get_name(0);
    my $period = $self->{'args'}[0];
    my $a = $self->{'args'}[1];
    
    return if ($indic->is_available($t3_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Calculate e1, e2, e3, e4, e5 and e6
    $self->{'e1'}->calculate_interval($calc, $i - $period * 5 + 5, $i);
    $self->{'e2'}->calculate_interval($calc, $i - $period * 4 + 4, $i);
    $self->{'e3'}->calculate_interval($calc, $i - $period * 3 + 3, $i);
    $self->{'e4'}->calculate_interval($calc, $i - $period * 2 + 2, $i);
    $self->{'e5'}->calculate_interval($calc, $i - $period + 1, $i);
    $self->{'e6'}->calculate($calc, $i);

    # Get e3, e4, e5 and e6
    my $e3 = $indic->get($self->{'e3'}->get_name, $i);
    my $e4 = $indic->get($self->{'e4'}->get_name, $i);
    my $e5 = $indic->get($self->{'e5'}->get_name, $i);
    my $e6 = $indic->get($self->{'e6'}->get_name, $i);

    # Calculate c1, c2, c3 and c4
    my $c1 = (-$a) ** 3;
    my $c2 = 3 * ($a ** 2) + 3 * ($a ** 3);
    my $c3 = -6 * ($a ** 2) - 3 * $a - 3 * ($a ** 3);
    my $c4 = 1 + 3 * $a + ($a ** 3) + 3 * ($a ** 2);
    
    # Calculate and return T3
    my $t3 = $c1 * $e6 + $c2 * $e5 + $c3 * $e4 + $c4 * $e3;
    $indic->set($t3_name, $i, $t3);
}

1;
