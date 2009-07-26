package Finance::GeniusTrader::Graphics::Object::MountainBand;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);
@ISA = qw(Finance::GeniusTrader::Graphics::Object);

use Finance::GeniusTrader::Graphics::Object;
use Finance::GeniusTrader::Graphics::Driver;
use Finance::GeniusTrader::Graphics::Tools qw(:color);
use Finance::GeniusTrader::Conf;

Finance::GeniusTrader::Conf::default("Graphic::MountainBand::Color", "black");

=head1 Finance::GeniusTrader::Graphics::Object::MountainBand

=cut

#
# note: implementation (see script graphic.pl) creates a datasource
#       with the first argument, then creates a second datasource
#       with the second argument.
#       the mountainband object combines both datasources
#
sub init {
    my ($self, $source2) = @_;
    $self->{"source2"} = $source2;
    
    # Default values ...
    $self->{'fg_color'} = get_color(Finance::GeniusTrader::Conf::get("Graphic::MountainBand::Color"));

}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
	        $scale->convert_to_x_coordinate($start);

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
        
	# clip at top of zone
        $y1  = $yc_max if ($y1 > $yc_max);
        $y2  = $yc_max if ($y2 > $yc_max);
        $y1l = $yc_max if ($y1l > $yc_max);
        $y2l = $yc_max if ($y2l > $yc_max);
	# clip at bottom of zone
        $y1  = $yc_min if ($y1 < $yc_min);
        $y2  = $yc_min if ($y2 < $yc_min);
        $y1l = $yc_min if ($y1l < $yc_min);
        $y2l = $yc_min if ($y2l < $yc_min);

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
