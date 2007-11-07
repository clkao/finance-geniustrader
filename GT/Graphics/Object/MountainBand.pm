package GT::Graphics::Object::MountainBand;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);
@ISA = qw(GT::Graphics::Object);

use GT::Graphics::Object;
use GT::Graphics::Driver;
use GT::Graphics::Tools qw(:color);
use GT::Conf;

GT::Conf::default("Graphic::MountainBand::Color", "black");

=head1 GT::Graphics::Object::MountainBand

=cut

sub init {
    my ($self, $source2) = @_;
    $self->{"source2"} = $source2;
    
    # Default values ...
    $self->{'fg_color'} = get_color(GT::Conf::get("Graphic::MountainBand::Color"));
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
	        $scale->convert_to_x_coordinate($start);
    my $y_zero = $scale->convert_to_y_coordinate(0);
    $y_zero = 0 if ($y_zero < 0);
    my $y_max = $zone->height;

    my ($first_pt, $second_pt);
    for(my $i = $start; $i <= $end; $i++)
    {
	# Find two available points
        if ($self->{'source'}->is_available($i) &&
	    $self->{'source2'}->is_available($i)) {
            $second_pt = $i;
        } else {
            next;
        }
        if (! defined($first_pt)) {
            $first_pt = $second_pt;
            next;
        }
        
	# Draw
	my $data1_1 = $self->{'source'}->get($first_pt);
	my $data1_2 = $self->{'source'}->get($second_pt);
	my $data2_1 = $self->{'source2'}->get($first_pt);
	my $data2_2 = $self->{'source2'}->get($second_pt);

	my ($x1, $y1) = $scale->convert_to_coordinate($first_pt, $data1_1);
	my ($x2, $y2) = $scale->convert_to_coordinate($second_pt, $data1_2);
	my $y1l = $scale->convert_to_y_coordinate($data2_1);
	my $y2l = $scale->convert_to_y_coordinate($data2_2);
	
	$x1 += int($space / 2);
	$x2 += int(($space-0.5) / 2);
	$y1 = $zone->height if ($y1 > $zone->height);
	$y2 = $zone->height if ($y2 > $zone->height);
	# clip at top of zone
	# $y1 = $zone->height if ($y1 > $zone->height);
	# $y2 = $zone->height if ($y2 > $zone->height);
	$y1  = $y_max if ($y1 > $y_max);
	$y2  = $y_max if ($y2 > $y_max);
	$y1l = $y_max if ($y1l > $y_max);
	$y2l = $y_max if ($y2l > $y_max);
	# clip at bottom of zone
	$y1  = $y_zero if ($y1 < $y_zero);
	$y2  = $y_zero if ($y2 < $y_zero);
	$y1l = $y_zero if ($y1l < $y_zero);
	$y2l = $y_zero if ($y2l < $y_zero);

	my @points = (
	    [$zone->absolute_coordinate($x1, $y1)],
	    [$zone->absolute_coordinate($x2, $y2)],
	    [$zone->absolute_coordinate($x2, $y2l)],
	    [$zone->absolute_coordinate($x1, $y1l)]
	);
	
	$driver->filled_polygon($picture, $self->{'fg_color'}, @points);

	# Shift the points
	$first_pt = $second_pt;
    }
}

1;
