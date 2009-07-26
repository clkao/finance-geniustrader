package Finance::GeniusTrader::Graphics::Zone;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use Finance::GeniusTrader::Graphics::Graphic;
use Finance::GeniusTrader::Graphics::Driver;
use Finance::GeniusTrader::Graphics::Axis;
use Finance::GeniusTrader::Tools qw(:math);
use Finance::GeniusTrader::Graphics::Tools qw(:color);
use Finance::GeniusTrader::Conf;

=head1 Finance::GeniusTrader::Graphics::Zone

A zone is a part of the graphic. It has an external size and an internal
size. The internal size may be split in several sub zones.

   ________________
  |  ____________  |
  | |            | |
  | | Int.  zone | |
  | |____________| |
  |________________|

A zone can also be considered like a « drawable » object and as such
it implements the display(...) method. It will call the display methods
for the axis, draw the border if needed and draw the title.
  
=head2 Finance::GeniusTrader::Graphics::Zone->new($width, $height, $left, $right, $top, $bottom);

Creates a new zone with the given internal size. $left, $right, $top, $bottom
is the free space to keep around the internal zone.

=cut
sub new {
    my $self = shift;
    my $type = ref($self) || $self;
    my ($w, $h, $l, $r, $t, $b) = @_;

    my $zone = { "childs" => [],
		 "parent" => undef,
		 "x" => 0, "y" => 0,
		 "width" => $w,
		 "height" => $h,
		 "left" =>   defined($l) ? $l : 0,
		 "right" =>  defined($r) ? $r : 0,
		 "top" =>    defined($t) ? $t : 0,
		 "bottom" => defined($b) ? $b : 0,
		 "border_width" => 0,
		 "border_color" => 
			get_color(Finance::GeniusTrader::Conf::get_first(
			    "Graphic::Zone::BorderColor",
			    "Graphic::ForegroundColor"
			)),
		 "font_name" => $FONT_ARIAL,
		 "font_size" => $FONT_SIZE_MEDIUM,
		 "font_color" => 
			get_color(Finance::GeniusTrader::Conf::get_first(
			    "Graphic::Zone::TitleColor",
			    "Graphic::ForegroundColor"
			))
	       };
    return bless $zone, $type;
}

=head2 $z->add_subzone($zx, $zy, $zone)

Add $zone as a subzone of the current zone and place it at position ($zx,$zy).
$zx and $zy are positive integers.

=cut
sub add_subzone {
    my ($self, $zx, $zy, $child) = @_;

    $self->{'childs'}[$zx][$zy] = $child;
    $child->set_parent($self);
    $child->set_position($zx, $zy);
}

=head2 ($ax, $ay) = $z->absolute_coordinate($x, $y)

Returns the absolute coordinate of the given point. ($x, $y) is
the coordinate in the zone $z. ($ax, $ay) are the coordinate of the
same point but in the root zone.

=cut
sub absolute_coordinate {
    my ($self, $x, $y) = @_;

    if ($self->{'parent'}) {
	my ($z_x, $z_y) = $self->{'parent'}->zone_coordinate($self->{'x'},
							     $self->{'y'});
	return $self->{'parent'}->absolute_coordinate(
					$self->{'left'} + $x + $z_x,
					$self->{'bottom'} + $y + $z_y);
    } else {
	return ($x + $self->{'left'}, $y + $self->{'bottom'});
    }
}

=head2 ($x, $y) = $z->zone_coordinate($zx, $zy)

Returns the bottom left coordinate of the zone identified by
($zx, $zy). This function will only give good results once all
zones have been created and linked together.

=cut
sub zone_coordinate {
    my ($self, $zx, $zy) = @_;

    my ($x, $y) = (0, 0);
    
    for (my $i = 0; $i < $zx; $i++) {
	if (defined($self->{'childs'}[$i][$zy])) {
	    $x += $self->{'childs'}[$i][$zy]->external_width();
	}
    }
    my $nby = scalar(@{$self->{'childs'}[$zx]});
    for (my $i = $nby; $i > $zy; $i--) {
	if (defined($self->{'childs'}[$zx][$i])) {
	    $y += $self->{'childs'}[$zx][$i]->external_height();
	}
    }
    return ($x, $y);
}

=head2 $z->update_size()

Update the size of the zone according to the size of the childs.

=cut
sub update_size {
    my ($self) = @_;
    my ($w, $h) = (0, 0);
    my $nb = 0;
    
    # Look for the height in the columns
    foreach my $column (grep { defined($_) } @{$self->{'childs'}}) {
	my $h_col = 0;
	$nb = max($nb, scalar @{$column});
	foreach (grep { defined($_) } @{$column}) {
	    $h_col += $_->external_height();
	}
	$h = max($h, $h_col);
    }

    # Look for the width in the rows
    for(my $i = 0; $i < $nb; $i++) {
	my $w_row = 0;
	for(my $j = 0; $j < scalar @{$self->{'childs'}}; $j++) {
	    next if (! defined($self->{'childs'}[$j][$i]));
	    $w_row += $self->{'childs'}[$j][$i]->external_width();
	}
	$w = max($w, $w_row);
    }

    $self->{'width'} = $w;
    $self->{'height'} = $h;
}

=head2 $z->get_subzone($zx, $zy)

Return the subzone indicated by the coordinate.

=cut
sub get_subzone {
    my ($self, $zx, $zy) = @_;

    return $self->{'childs'}[$zx][$zy];
}

=head2 $z->set_axis_{left,right,top,bottom}($axis)

Put an axis on the indicated side.

=cut
sub set_axis_left   { $_[0]->{'axis_left'} = $_[1] }
sub set_axis_right  { $_[0]->{'axis_right'} = $_[1] }
sub set_axis_top    { $_[0]->{'axis_top'} = $_[1] }
sub set_axis_bottom { $_[0]->{'axis_bottom'} = $_[1] }

=head2 $z->get_axis_{left,right,top,bottom}() 

Get the axis of the indicated side.

=cut
sub get_axis_left   { $_[0]->{'axis_left'} }
sub get_axis_right  { $_[0]->{'axis_right'} }
sub get_axis_top    { $_[0]->{'axis_top'} }
sub get_axis_bottom { $_[0]->{'axis_bottom'} }

=head2 $z->set_title_{left,right,top,bottom}($title)

Put a title on the indicated side.

=cut
sub set_title_left   { $_[0]->{'title_left'} = $_[1] }
sub set_title_right  { $_[0]->{'title_right'} = $_[1] }
sub set_title_top    { $_[0]->{'title_top'} = $_[1] }
sub set_title_bottom { $_[0]->{'title_bottom'} = $_[1] }

=head2 $z->get_title_{left,right,top,bottom}() 

Get the title of the indicated side.

=cut
sub get_title_left   { $_[0]->{'title_left'} }
sub get_title_right  { $_[0]->{'title_right'} }
sub get_title_top    { $_[0]->{'title_top'} }
sub get_title_bottom { $_[0]->{'title_bottom'} }

=head2 $z->set_title_font_name($name)

=head2 $z->set_title_font_size($size)

=head2 $z->set_title_font_color($size)

Those 3 methods are used to change the font for the title.

=cut
sub set_title_font_name {
    my ($self, $name) = @_;
    $self->{'font_name'} = $name;
}
sub set_title_font_size {
    my ($self, $size) = @_;
    $self->{'font_size'} = $size;
}
sub set_title_font_color {
    my ($self, $color) = @_;
    $self->{'font_color'} = $color;
}

=head2 $z->set_default_scale($scale)

Use $scale as the default scale for this zone.

=cut
sub set_default_scale { $_[0]->{'default_scale'} = $_[1] }
sub get_default_scale { $_[0]->{'default_scale'} }

=head2 $z->set_border_width($width) 

Add a border of the given width around the zone. It will not sharp the zone
but extend/decrease the space around it.

=cut
sub set_border_width {
    my ($self, $width) = @_;
    my $change = $width - $self->{'border_width'};
    $self->{'left'} += $change;
    $self->{'right'} += $change;
    $self->{'top'} += $change;
    $self->{'bottom'} += $change;
    $self->{'border_width'} = $width;
}

=head2 $z->set_border_color([$R,$G,$B])

Change the color of the border.

=cut
sub set_border_color {
    my ($self, $color) = @_;
    $self->{'border_color'} = $color;
}

=head2 $z->includes_point($x, $y, [$extented])

Returns true if the point is within the zone, false otherwise.
If $extended is true, the border of the zone is considered as part
of the zone.

=cut
sub includes_point {
    my ($self, $x, $y, $extended) = @_;
    if (defined($extended) && $extended) {
	return (($x >= - $self->{'left'}) && 
		($x < $self->{'width'} + $self->{'right'}) &&
		($y >= - $self->{'bottom'}) &&
		($y < $self->{'height'} + $self->{'top'}));
    } else {
	return (($x >= 0) && ($x < $self->{'width'}) &&
		($y >= 0) && ($y < $self->{'height'}));
    }
}

=head2 $z->display($driver, $graphic)

Display the zone with its axis, its borders and its titles.

=cut
sub display {
    my ($self, $driver, $picture) = @_;
    my $offset = ($self->{'border_width'} > 0) ? 1 : 0;
    if (defined($self->{'axis_left'})) {
	$self->{'axis_left'}->set_left_side();
	$self->{'axis_left'}->set_zone($self);
	$self->{'axis_left'}->set_rectangle(- $self->{'left'}, 0,
				- $self->{'border_width'} - 1 + $offset,
				$self->{'height'});
	$self->{'axis_left'}->display($driver, $picture);
    }
    if (defined($self->{'axis_right'})) {
	$self->{'axis_right'}->set_right_side();
	$self->{'axis_right'}->set_zone($self);
	$self->{'axis_right'}->set_rectangle($self->{'width'} + 
				$self->{'border_width'} - $offset, 0,
				$self->{'width'} + $self->{'right'},
				$self->{'height'});
	$self->{'axis_right'}->display($driver, $picture);
    }
    if (defined($self->{'axis_top'})) {
	$self->{'axis_top'}->set_top_side();
	$self->{'axis_top'}->set_zone($self);
	$self->{'axis_top'}->set_rectangle(0, $self->{'height'} + 
				$self->{'border_width'} - $offset,
				$self->{'width'}, $self->{'height'} +
				$self->{'top'});
	$self->{'axis_top'}->display($driver, $picture);
    }
    if (defined($self->{'axis_bottom'})) {
	$self->{'axis_bottom'}->set_bottom_side();
	$self->{'axis_bottom'}->set_zone($self);
	$self->{'axis_bottom'}->set_rectangle(0, - $self->{'bottom'},
				$self->{'width'}, 
				- $self->{'border_width'} - 1 + $offset);
	$self->{'axis_bottom'}->display($driver, $picture);
    }

    for (my $i = 1; $i <= $self->{'border_width'}; $i++) {
	$driver->rectangle($picture, $self->absolute_coordinate(- $i, - $i),
			   $self->absolute_coordinate($self->{'width'} - 1 + $i,
			   $self->{'height'} - 1 + $i),
			   $self->{'border_color'});
    }

    if ($self->{'title_left'}) {
	$driver->string($picture, $self->{'font_name'},
		    $self->{'font_size'}, $self->{'font_color'},
		    $self->absolute_coordinate(
		      - $self->{'left'}, int($self->{'height'} / 2)),
		    $self->{'title_left'}, $ALIGN_LEFT, $ALIGN_CENTER,
		    $ORIENTATION_UP);
    }
    if ($self->{'title_right'}) {
	$driver->string($picture, $self->{'font_name'},
		    $self->{'font_size'}, $self->{'font_color'},
		    $self->absolute_coordinate(
		      $self->{'right'} + $self->{'width'} - 1,
		      int($self->{'height'} / 2)),
		    $self->{'title_right'}, $ALIGN_RIGHT, $ALIGN_CENTER,
		    $ORIENTATION_DOWN);
    }
    if ($self->{'title_top'}) {
	$driver->string($picture, $self->{'font_name'},
		    $self->{'font_size'}, $self->{'font_color'},
		    $self->absolute_coordinate(
		      int($self->{'width'} / 2), 
		      $self->{'height'} + $self->{'top'} - 1),
		    $self->{'title_top'}, $ALIGN_CENTER, $ALIGN_TOP);
    }
    if ($self->{'title_bottom'}) {
	$driver->string($picture, $self->{'font_name'},
		    $self->{'font_size'}, $self->{'font_color'},
		    $self->absolute_coordinate(
		      int($self->{'width'} / 2), 
		      - $self->{'bottom'}),
		    $self->{'title_bottom'}, $ALIGN_CENTER, $ALIGN_BOTTOM);
    }

    foreach my $array (grep { defined($_) } @{$self->{'childs'}}) {
	foreach my $subzone (grep { defined($_) } @{$array}) {
	    $subzone->display($driver, $picture);
	}
    }
}

=head1 SIMPLE FUNCTIONS

=head2 $z->width() && $z->height()

=head2 $z->external_width() && $z->external_height()

=cut
sub width  { $_[0]->{'width'} }
sub height { $_[0]->{'height'} }
sub external_width { $_[0]->{'width'} + $_[0]->{'left'} + $_[0]->{'right'} }
sub external_height { $_[0]->{'height'} + $_[0]->{'top'} + $_[0]->{'bottom'} }

=head2 ($x, $y) = $z->get_position()

=head2 $z->get_parent()

=cut
sub get_position { return ($_[0]->{'x'}, $_[0]->{'y'}) }
sub get_parent { $_[0]->{'parent'} }

=head1 INTERNAL FUNCTIONS

=head2 $z->set_parent($parent)

=head2 $z->set_position($zx, $zy)

=cut
sub set_parent { $_[0]->{'parent'} = $_[1] }
sub set_position { $_[0]->{'x'} = $_[1]; $_[0]->{'y'} = $_[2]; }

1;
