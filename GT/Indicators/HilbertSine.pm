package GT::Indicators::HilbertSine;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Indicators::WTCL;
use GT::Indicators::HilbertPeriod;
use GT::Prices;
use GT::Tools qw(:math);
use POSIX;

@ISA = qw(GT::Indicators);
@NAMES = ("HilbertSine", "HilbertLeadSine");

=head1 GT::Indicators::HilbertSine

=head2 Overview

=head2 Calculation

=head2 Examples

=head2 Links

TASC May 2000 - page 27

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args) = @_;
    my $self = { 'args' => defined($args) ? $args : [] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my $self = shift;
    
    $self->{'median'} = GT::Indicators::WTCL->new([0]);
    $self->{'period'} = GT::Indicators::HilbertPeriod->new;

    $self->add_indicator_dependency($self->{'period'}, 1);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    
    return if ($indic->is_available($self->get_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $period = $indic->get($self->{'period'}->get_name, $i);

    return if ($period > $i + 1);
    
    $self->{'median'}->calculate_interval($calc, $i - $period + 1, $i);
    
    my ($real, $imag) = (0, 0);
    for (my $n = 0; $n < $period; $n++)
    {
	my $price = $indic->get($self->{'median'}->get_name, $i - $n);
	$real += sin(2 * PI * $n / int($period)) * $price;
	$imag += cos(2 * PI * $n / int($period)) * $price;
    }

    my $phase = 0;
    if (abs($imag) > 0.001) {
	$phase = POSIX::atan($real / $imag);
    } else {
	$phase = PI / 2 * sign($real);
    }

    if (($period < 30) && ($period > 0)) {
	$phase += (6.818 / $period - 0.227) * 2 * PI;
    }

    $phase += PI / 2;
    if ($imag < 0) { $phase += PI }
    if ($phase > 7 / 8 * 2 * PI) { $phase -= 2 * PI }
    
    $indic->set($self->get_name(0), $i, sin($phase));
    $indic->set($self->get_name(1), $i, sin($phase + PI / 4));
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    $self->{'period'}->calculate_interval($calc, $first, $last);
    $self->{'median'}->calculate_interval($calc, $first, $last);
    for (my $i = $first; $i <= $last; $i++)
    {
	$self->calculate($calc, $i);
    }
}

1;
