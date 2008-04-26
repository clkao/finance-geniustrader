package GT::Indicators::InstantTrendLine;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Indicators::WMA;
use GT::Indicators::WTCL;
use GT::Indicators::HilbertPeriod;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("InstantTrendLine");

=head1 GT::Indicators::InstantTrendLine

=head2 Overview

=head2 Calculation

=head2 Examples

=head2 Links

TASC May 2000 - page 22

=cut
sub initialize {
    my $self = shift;
    
    $self->{'median'} = GT::Indicators::WTCL->new([0]);
    $self->{'period'} = GT::Indicators::HilbertPeriod->new;

    $self->add_indicator_dependency($self->{'period'}, 1);
}

=head2 GT::Indicators::InstantTrendLine::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    
    return if ($indic->is_available($self->get_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $period = $indic->get($self->{'period'}->get_name, $i);
    
    $self->{'median'}->calculate_interval($calc, $i - $period - 1, $i);
    
    my $trendline = 0;
    for (my $n = 0; $n <= $period + 1; $n++)
    {
	$trendline += $indic->get($self->{'median'}->get_name, $i - $n);
    }
    $trendline /= $period + 2;
	
    $indic->set($self->get_name, $i, $trendline);
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
