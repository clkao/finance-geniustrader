package Finance::GeniusTrader::Graphics::Object::Curve;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);
@ISA = qw(Finance::GeniusTrader::Graphics::Object);

use Finance::GeniusTrader::Graphics::Graphic;
use Finance::GeniusTrader::Graphics::Object;
use Finance::GeniusTrader::Graphics::Driver;
use Finance::GeniusTrader::Graphics::Tools qw(:color);
use Finance::GeniusTrader::Conf;

=head1 Finance::GeniusTrader::Graphics::Object::Curve

This graphical object display a curve.

=cut

sub init {
    my ($self) = @_;
    
    # Default values ... maybe we should use Finance::GeniusTrader::Conf ?
    $self->{'fg_color'} = get_color(Finance::GeniusTrader::Conf::get("Graphic::ForegroundColor"));
    $self->{'aa'} = 1;
    $self->{'linewidth'} = 1;
}

sub set_antialiased {
    my ($self, $aa) = @_;
    $self->{'aa'} = $aa;
}

sub set_linewidth {
    my ($self, $lw) = @_;
    $self->{'linewidth'} = $lw;
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
	if ($self->{'source'}->is_available($i)) {
	    $second_pt = $i;
	} else {
	    next;
	}
	if (! defined($first_pt)) {
	    $first_pt = $second_pt;
	    next;
	}
	
	# Now we have two points, let's display if possible
	my $data1 = $self->{'source'}->get($first_pt);
	my $data2 = $self->{'source'}->get($second_pt);
	my ($x1, $y1) = $scale->convert_to_coordinate($first_pt, $data1);
	my ($x2, $y2) = $scale->convert_to_coordinate($second_pt, $data2);
	$x1 += int($space / 2);
	$x2 += int($space / 2);

        # rather than skip plotting the curve that exceeds a zone boundary
        # this change will plot to and along the zone boundary

        # clip at top of zone
        $y1 = $yc_max if ($y1 > $yc_max);
        $y2 = $yc_max if ($y2 > $yc_max);
        # clip at bottom of zone
        $y1 = $yc_min if ($y1 < $yc_min);
        $y2 = $yc_min if ($y2 < $yc_min);

	    my $oldlw = $driver->line_width($picture, $self->{'linewidth'});
	    if ($self->{'aa'}) {
		$driver->antialiased_line($picture, 
		    $zone->absolute_coordinate($x1, $y1),
		    $zone->absolute_coordinate($x2, $y2),
		    $self->{'fg_color'});
	    } else {
		$driver->line($picture, 
		    $zone->absolute_coordinate($x1, $y1),
		    $zone->absolute_coordinate($x2, $y2),
		    $self->{'fg_color'});
	    }
	    $driver->line_width($picture, $oldlw);

	# Shift the points
	$first_pt = $second_pt;
    }
}

1;
