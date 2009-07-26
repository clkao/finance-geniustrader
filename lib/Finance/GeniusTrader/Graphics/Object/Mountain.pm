package Finance::GeniusTrader::Graphics::Object::Mountain;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# ras version -- includes gmargo@pacbell.net patch 12dec06
# $Id$

use strict;
use vars qw(@ISA);
@ISA = qw(Finance::GeniusTrader::Graphics::Object);

use Finance::GeniusTrader::Graphics::Object;
use Finance::GeniusTrader::Graphics::Driver;
use Finance::GeniusTrader::Graphics::Tools qw(:color);
use Finance::GeniusTrader::Conf;

Finance::GeniusTrader::Conf::default("Graphic::Mountain::Color", "black");

=head1 Finance::GeniusTrader::Graphics::Object::Mountain

=cut

sub init {
    my ($self) = @_;
    
    # Default values ...
    $self->{'fg_color'} = get_color(Finance::GeniusTrader::Conf::get("Graphic::Mountain::Color"));
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
	        $scale->convert_to_x_coordinate($start);
    my $y_zero = $scale->convert_to_y_coordinate(0);

    # only $y_min and $y_max are significant
    my ($x_min, $y_min) = $scale->get_value_from_coordinate($start, 0);
    my ($x_max, $y_max) = $scale->get_value_from_coordinate($end, $zone->height-1);

    # these are coordinate values of $y_min and $y_max
    my $yc_min = $scale->convert_to_y_coordinate($y_min);
    my $yc_max = $scale->convert_to_y_coordinate($y_max);

	my ($first_pt, $second_pt);
    for(my $i = $start; $i <= $end; $i++)
	{
	# Find two available points
        if ($self->{'source'}->is_available($i)) {
            $second_pt = $i;
        } else {
            next;
        }
        if (! defined($first_pt)) {
            $first_pt = $second_pt;
            next;
        }
        
	# Draw
	my $data1 = $self->{'source'}->get($first_pt);
	my $data2 = $self->{'source'}->get($second_pt);
	my ($x1, $y1) = $scale->convert_to_coordinate($first_pt, $data1);
	my ($x2, $y2) = $scale->convert_to_coordinate($second_pt, $data2);
	$x1 += int($space / 2);
	$x2 += int(($space-0.5) / 2);

	# clip at top of zone
	$y1 = $yc_max if ($y1 > $yc_max);
	$y2 = $yc_max if ($y2 > $yc_max);
	# clip at bottom of zone
	$y1 = $yc_min if ($y1 < $yc_min);
	$y2 = $yc_min if ($y2 < $yc_min);

	my @points = (
	    [$zone->absolute_coordinate($x1, $y1)],
	    [$zone->absolute_coordinate($x2, $y2)],
	    [$zone->absolute_coordinate($x2, $y_zero)],
	    [$zone->absolute_coordinate($x1, $y_zero)]
	);
	
	$driver->filled_polygon($picture, $self->{'fg_color'}, @points);

	# Shift the points
	$first_pt = $second_pt;
    }
}

1;
