package GT::Indicators::T3;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::EMA;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("T3[#1,#2]");
@DEFAULT_ARGS = (5, 0.7);

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

=cut

sub initialize {
    my $self = shift;
    
    # Initialize e1, e2, e3, e4, e5 and e6
    my $period = $self->{'args'}->get_arg_names(1);
    $self->{'e1'} = GT::Indicators::EMA->new([ $period ]);
    
    $self->{'e2'} = GT::Indicators::EMA->new([ $period, "{I:Generic:ByName " . $self->{'e1'}->get_name . "}" ]);
    
    $self->{'e3'} = GT::Indicators::EMA->new([ $period, "{I:Generic:ByName " . $self->{'e2'}->get_name . "}" ]);
    
    $self->{'e4'} = GT::Indicators::EMA->new([ $period, "{I:Generic:ByName " . $self->{'e3'}->get_name . "}" ]);
    
    $self->{'e5'} = GT::Indicators::EMA->new([ $period, "{I:Generic:ByName " . $self->{'e4'}->get_name . "}" ]);
    
    $self->{'e6'} = GT::Indicators::EMA->new([ $period, "{I:Generic:ByName " . $self->{'e5'}->get_name . "}" ]);

    $self->add_indicator_dependency($self->{'e1'}, $period * 5 - 4);
    $self->add_indicator_dependency($self->{'e2'}, $period * 4 - 3);
    $self->add_indicator_dependency($self->{'e3'}, $period * 3 - 2);
    $self->add_indicator_dependency($self->{'e4'}, $period * 2 - 1);
    $self->add_indicator_dependency($self->{'e5'}, $period);
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
    my $period = $self->{'args'}->get_arg_constant(1);
    my $a = $self->{'args'}->get_arg_constant(2);
    
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
