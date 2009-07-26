package GT::Graphics::Axis;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use GT::Graphics::Graphic;
use GT::Graphics::Driver;
use GT::Graphics::Scale;
use GT::Graphics::Tools qw(:color);
use GT::Conf;

GT::Conf::default("Graphic::Grid::Color", "light grey");

=head1 GT::Graphics::Axis

An axis can be displayed on a side of a Zone. It's associated to a scale.
It precises how much space there's between ticks.

=head2 GT::Graphics::Axis->new($scale)

Create a new axis and use the associated scale.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $scale = shift;
    my $self = { 'scale' => $scale, 
		 "color" => 
		    get_color(GT::Conf::get("Graphic::ForegroundColor")),
		 'grid_level' => 1, 
		 "grid_color" => 
			    get_color(GT::Conf::get("Graphic::Grid::Color")),
		 'label' => 1
	       };
    return bless $self, $class;
}

=head2 $a->set_{left,right,top,bottom}_side()

Indicate that the axis is on the corresponding side of the graphic.

=cut
sub set_left_side   { $_[0]->{'side'} = "left"; }
sub set_right_side  { $_[0]->{'side'} = "right"; }
sub set_top_side    { $_[0]->{'side'} = "top"; }
sub set_bottom_side { $_[0]->{'side'} = "bottom"; }

=head2 $a->set_zone($zone)

Indicate the zone attached to the axis.

=cut
sub set_zone { $_[0]->{'zone'} = $_[1] }

=head2 $a->set_rectangle($x1, $y1, $x2, $y2)

Indicate the rectangle in which the axis should be displayed. The
rectangle is defined by the lower left corner (x1,y1) and the upper
right corner (x2,y2).

=cut
sub set_rectangle {
    my ($self, $x1, $y1, $x2, $y2) = @_;
    $self->{'x1'} = $x1;
    $self->{'y1'} = $y1;
    $self->{'x2'} = $x2;
    $self->{'y2'} = $y2;
}

=head2 $a->set_space_for(_big)_ticks

Define the space between (big) ticks.

=cut
sub set_space_for_ticks { $_[0]->{'tick'} = $_[1] }
sub set_space_for_big_ticks { $_[0]->{'big_tick'} = $_[1] }

=head2 $a->set_grid_level({0|1|2})

Indicate if a grid should be displayed :
- 0 => no grid
- 1 => grid on big ticks
- 2 => grid on all ticks

=cut
sub set_grid_level {
    my ($self, $level) = @_;
    $self->{'grid_level'} = $level;
}

=head2 $a->set_grid_color($color)

Use the indicated color for the grid.

=cut
sub set_grid_color {
    my ($self, $color) = @_;
    $self->{'grid_color'} = get_color($color);
}

=head2 $a->label_display({0|1})

Tell if labels should be displayed or not.

=cut
sub label_display {
    my ($self, $label) = @_;
    $self->{'label'} = $label;
}

=head2 $a->set_custom_ticks([[$x,$label], ...], $below_zone)

Use the given custom ticks. If $below_zone is set to one, the labels
will be displayed below the zone starting at the given coordinate, otherwise
it will be displayed right below the given coordinate (ie below the tick).

=cut
sub set_custom_ticks {
    my ($self, $ticks, $below_zone) = @_;
    $below_zone = 0 if (! defined($below_zone));
    $self->{'custom_ticks'} = $ticks;
    $self->{'custom_ticks_below_zone'} = $below_zone;
}

=head2 $a->set_custom_big_ticks([[$x,$label], ...], $below_zone)

Use the given custom big ticks. If $below_zone is set to one, the labels
will be displayed below the zone starting at the given coordinate, otherwise
it will be displayed right below the given coordinate (ie below the tick).

=cut
sub set_custom_big_ticks {
    my ($self, $ticks, $below_zone) = @_;
    $below_zone = 0 if (! defined($below_zone));
    $self->{'custom_big_ticks'} = $ticks;
    $self->{'custom_big_ticks_below_zone'} = $below_zone;
}

=head2 $a->display($driver, $picture)

Display the axis on the picture.

=cut
sub display {
    my ($self, $driver, $picture) = @_;
    my ($offset_x, $offset_y, $fixed_x, $fixed_y) = (0, 0);
    my $scale = $self->{'scale'};
    my $zone = $self->{'zone'};
    
    if ($self->{'side'} eq "left") {
	$offset_x = -1;
	$fixed_x = $self->{'x2'};
    } elsif ($self->{'side'} eq "right") {
	$offset_x = 1;
	$fixed_x = $self->{'x1'};
    } elsif ($self->{'side'} eq "top") {
	$offset_y = 1;
	$fixed_y = $self->{'y1'};
    } elsif ($self->{'side'} eq "bottom") {
	$offset_y = -1;
	$fixed_y = $self->{'y2'};
    }
    
    my ($ll_x, $ll_y) = $zone->absolute_coordinate(0,0);
    my ($ur_x, $ur_y) = $zone->absolute_coordinate($zone->width() - 1,
						   $zone->height() - 1);
    
    if (defined($fixed_x)) {
	# Vertical axis
	my ($x1, $y1) = $scale->get_value_from_coordinate(0, 0);
	my ($x2, $y2) = $scale->get_value_from_coordinate(0, 
							  $zone->height() - 1);
	$driver->line($picture, 
	    $zone->absolute_coordinate($fixed_x, 0), 
	    $zone->absolute_coordinate($fixed_x, $zone->height() - 1),
	    $self->{'color'});
	# Simple ticks
	if ($self->{'tick'}) {
	my $factor = int($y1 / $self->{'tick'} + 0.999);
	while ($factor * $self->{'tick'} < $y2) {
	    my ($nx, $ny) = $zone->absolute_coordinate($fixed_x,
			($scale->convert_to_coordinate($x1, 
					    $factor * $self->{'tick'}))[1]);
	    $driver->line($picture, $nx, $ny, $nx + $offset_x * 3, $ny,
			  $self->{'color'});
	    if ($self->{'grid_level'} >= 2) {
		$driver->line($picture, $ll_x, $ny, $ur_x, $ny,
		    $self->{'grid_color'});
	    }
	    $factor++;
	}
	}
	# Simple big ticks
	if ($self->{'big_tick'}) {
	my $factor = int($y1 / $self->{'big_tick'} + 0.999);
	while ($factor * $self->{'big_tick'} < $y2) {
	    my ($nx, $ny) = $zone->absolute_coordinate($fixed_x,
			($scale->convert_to_coordinate($x1, 
					    $factor * $self->{'big_tick'}))[1]);
	    $driver->line($picture, $nx, $ny, $nx + $offset_x * 5, $ny,
			  $self->{'color'});
	    $driver->string($picture, $FONT_ARIAL, $FONT_SIZE_TINY,
			    $self->{'color'}, $nx + $offset_x * 7, $ny,
			    sprintf("%.1f", $factor * $self->{'big_tick'}),
			    ($offset_x > 0) ? $ALIGN_LEFT : $ALIGN_RIGHT,
			    $ALIGN_CENTER) if ($self->{'label'});
	    if ($self->{'grid_level'} >= 1) {
		$driver->line($picture, $ll_x, $ny, $ur_x, $ny,
		    $self->{'grid_color'});
	    }
	    $factor++;
	}
	}
	# Custom ticks
	if (defined($self->{'custom_ticks'})) {
	    my $c = $self->{'custom_ticks'};
	    my $b = $self->{'custom_ticks_below_zone'};
	    for(my $i = 0; $i < scalar(@{$c}); $i++) {
		my $ly = $scale->convert_to_y_coordinate($c->[$i][0]);
		next if (($ly < 0) || ($ly > $zone->height()));
		my ($nx, $ny) = $zone->absolute_coordinate($fixed_x, $ly);
		$driver->line($picture, $nx, $ny, $nx + $offset_x * 3, $ny,
			      $self->{'color'});
		my $zone_offset = 0;
		if ($b) {
		    if (defined($c->[$i+1])) {
			$zone_offset = int(($scale->convert_to_y_coordinate(
			    $c->[$i+1][0]) - $ly) / 2);
		    } else {
			$zone_offset = int(($zone->height() - $ly) / 2);
		    }
		}
		$driver->string($picture, $FONT_ARIAL, $FONT_SIZE_TINY,
			    $self->{'color'}, $nx + $offset_x * 5, 
			    $ny + $zone_offset, $c->[$i][1],
			    ($offset_x > 0) ? $ALIGN_LEFT : $ALIGN_RIGHT,
			    $ALIGN_CENTER) if ($self->{'label'} && 
					       ($c->[$i][1] ne ""));
		if ($self->{'grid_level'} >= 2) {
		    $driver->line($picture, $ll_x, $ny, $ur_x, $ny,
			    $self->{'grid_color'});
		}
	    }
	}
	# Custom big ticks
	if (defined($self->{'custom_big_ticks'})) {
	    my $c = $self->{'custom_big_ticks'};
	    my $b = $self->{'custom_big_ticks_below_zone'};
	    for(my $i = 0; $i < scalar(@{$c}); $i++) {
		my $ly = $scale->convert_to_y_coordinate($c->[$i][0]);
		next if (($ly < 0) || ($ly > $zone->height()));
		my ($nx, $ny) = $zone->absolute_coordinate($fixed_x, $ly);
		$driver->line($picture, $nx, $ny, $nx + $offset_x * 5, $ny,
			      $self->{'color'});
		my $zone_offset = 0;
		if ($b) {
		    if (defined($c->[$i+1])) {
			$zone_offset = int(($scale->convert_to_y_coordinate(
			    $c->[$i+1][0]) - $ly) / 2);
		    } else {
			$zone_offset = int(($zone->height() - $ly) / 2);
		    }
		}
		$driver->string($picture, $FONT_ARIAL, $FONT_SIZE_TINY,
			    $self->{'color'}, $nx + $offset_x * 7, 
			    $ny + $zone_offset, $c->[$i][1],
			    ($offset_x > 0) ? $ALIGN_LEFT : $ALIGN_RIGHT,
			    $ALIGN_CENTER) if ($self->{'label'} && 
			                       ($c->[$i][1] ne ""));
		if ($self->{'grid_level'} >= 1) {
		    $driver->line($picture, $ll_x, $ny, $ur_x, $ny,
			    $self->{'grid_color'});
		}
	    }
	}

    } elsif (defined($fixed_y)) {
	# Horizontal axis
	my ($x1, $y1) = $scale->get_value_from_coordinate(0, 0);
	my ($x2, $y2) = $scale->get_value_from_coordinate(
					    $zone->width() - 1, 0);
	$driver->line($picture, 
	    $zone->absolute_coordinate(0, $fixed_y), 
	    $zone->absolute_coordinate( $zone->width() - 1, $fixed_y),
	    $self->{'color'});
	if ($self->{'tick'}) {
	my $factor = int($x1 / $self->{'tick'} + 0.999);
	while ($factor * $self->{'tick'} < $x2) {
	    my ($nx, $ny) = $zone->absolute_coordinate(
			($scale->convert_to_coordinate( 
				$factor * $self->{'tick'}, $y1
			))[0], $fixed_y);
	    $driver->line($picture, $nx, $ny, $nx, $ny + $offset_y * 3,
			  $self->{'color'});
	    if ($self->{'grid_level'} >= 2) {
		$driver->line($picture, $nx, $ll_y, $nx, $ur_y,
		    $self->{'grid_color'});
	    }
	    $factor++;
	}
	}
	if ($self->{'big_tick'}) {
	my $factor = int($x1 / $self->{'big_tick'} + 0.999);
	while ($factor * $self->{'big_tick'} < $x2) {
	    my ($nx, $ny) = $zone->absolute_coordinate(
			($scale->convert_to_coordinate(
				$factor * $self->{'big_tick'}, $y1)
			)[0],
			$fixed_y);
	    $driver->line($picture, $nx, $ny, $nx, $ny + $offset_y * 5,
			  $self->{'color'});
	    $driver->string($picture, $FONT_ARIAL, $FONT_SIZE_TINY,
			    $self->{'color'}, $nx, $ny + $offset_y * 7,
			    sprintf("%.1f", $factor * $self->{'big_tick'}),
			    $ALIGN_CENTER,
			    ($offset_y > 0) ? $ALIGN_BOTTOM : $ALIGN_TOP
			    ) if ($self->{'label'});
	    if ($self->{'grid_level'} >= 1) {
		$driver->line($picture, $nx, $ll_y, $nx, $ur_y,
		    $self->{'grid_color'});
	    }
	    $factor++;
	}
	}
	# Custom ticks
	if (defined($self->{'custom_ticks'})) {
	    my $c = $self->{'custom_ticks'};
	    my $b = $self->{'custom_ticks_below_zone'};
	    for(my $i = 0; $i < scalar(@{$c}); $i++) {
		my $lx = $scale->convert_to_x_coordinate($c->[$i][0]);
		next if (($lx < 0) || ($lx > $zone->width()));
		my ($nx, $ny) = $zone->absolute_coordinate($lx, $fixed_y);
		$driver->line($picture, $nx, $ny, $nx, $ny + $offset_y * 3,
			      $self->{'color'});
		my $zone_offset = 0;
		if ($b) {
		    if (defined($c->[$i+1])) {
			$zone_offset = int(($scale->convert_to_x_coordinate(
			    $c->[$i+1][0]) - $lx) / 2);
		    } else {
			$zone_offset = int(($zone->width() - $lx) / 2);
		    }
		}
		$driver->string($picture, $FONT_ARIAL, $FONT_SIZE_TINY,
			    $self->{'color'}, $nx + $zone_offset, 
			    $ny + $offset_y * 5, $c->[$i][1],
			    $ALIGN_CENTER,
			    ($offset_y > 0) ? $ALIGN_BOTTOM : $ALIGN_TOP,
			    ) if ($self->{'label'} && ($c->[$i][1] ne ""));
		if ($self->{'grid_level'} >= 2) {
		    $driver->line($picture, $nx, $ll_y, $nx, $ur_y,
			    $self->{'grid_color'});
		}
	    }
	}
	# Custom big ticks
	if (defined($self->{'custom_big_ticks'})) {
	    my $c = $self->{'custom_big_ticks'};
	    my $b = $self->{'custom_big_ticks_below_zone'};
	    for(my $i = 0; $i < scalar(@{$c}); $i++) {
		my $lx = $scale->convert_to_x_coordinate($c->[$i][0]);
		next if (($lx < 0) || ($lx > $zone->width()));
		my ($nx, $ny) = $zone->absolute_coordinate($lx, $fixed_y);
		$driver->line($picture, $nx, $ny, $nx, $ny + $offset_y * 5,
			      $self->{'color'});
		my $zone_offset = 0;
		if ($b) {
		    if (defined($c->[$i+1])) {
			$zone_offset = int(($scale->convert_to_x_coordinate(
			    $c->[$i+1][0]) - $lx) / 2);
		    } else {
			$zone_offset = int(($zone->width() - $lx) / 2);
		    }
		}
		$driver->string($picture, $FONT_ARIAL, $FONT_SIZE_TINY,
			    $self->{'color'}, $nx + $zone_offset, 
			    $ny + $offset_y * 7, $c->[$i][1],
			    $ALIGN_CENTER,
			    ($offset_y > 0) ? $ALIGN_BOTTOM : $ALIGN_TOP,
			    ) if ($self->{'label'} && ($c->[$i][1] ne ""));
		if ($self->{'grid_level'} >= 1) {
		    $driver->line($picture, $nx, $ll_y, $nx, $ur_y,
			    $self->{'grid_color'});
		}
	    }
	}

    }
}

1;
