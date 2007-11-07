package GT::Graphics::Object::Curve;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);
@ISA = qw(GT::Graphics::Object);

use GT::Graphics::Graphic;
use GT::Graphics::Object;
use GT::Graphics::Driver;
use GT::Graphics::Tools qw(:color);
use GT::Conf;

=head1 GT::Graphics::Object::Curve

This graphical object display a curve.

=cut

sub init {
    my ($self) = @_;
    
    # Default values ... maybe we should use GT::Conf ?
    $self->{'fg_color'} = get_color(GT::Conf::get("Graphic::ForegroundColor"));
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

    my $y_zero = $scale->convert_to_y_coordinate(0);
    $y_zero = 0 if ($y_zero < 0);
    my $y_max = $zone->height;

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

        # rather than skip plotting the curve that exceeds the zone boundary
        # this change will plot to the zone boundary
        # line segments that lie outside the zone are not plotted
        #if ($zone->includes_point($x1, $y1) && $zone->includes_point($x2, $y2))
        #{
        my $pt1 = $zone->includes_point($x1, $y1);
        my $pt2 = $zone->includes_point($x2, $y2);

        # if neither point within zone skip
        if ( ! $pt1 && ! $pt2 ) {
          # Shift the points
          $first_pt = $second_pt;
          next;
        } elsif ( $pt1 && ! $pt2 ) {
          # if pt1 but not pt2 within zone set pt2 at limit and draw
          # clip at edge of zone pt2
          $y2  = $y_max  if ($y2 > $y_max);
          $y2  = $y_zero if ($y2 < $y_zero);
        } elsif ( ! $pt1 && $pt2 ) {
        # if not pt1 but pt2 within zone set pt1 at limit and draw
          # clip at edge of zone pt1
          $y1 = $y_max  if ($y1 > $y_max);
          $y1 = $y_zero if ($y1 < $y_zero);
        }

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
