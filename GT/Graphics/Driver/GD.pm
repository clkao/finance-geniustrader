package GT::Graphics::Driver::GD;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use GT::Graphics::Driver;
use GD;
use GT::Graphics::Zone;

our @ISA = qw(GT::Graphics::Driver);

=head1 GT::Graphics::Driver::GD

The GD driver implements the drawing primitives using the GD module
that lets you create PNG images.

=cut

# PUBLIC DRIVER INTERFACE
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    return bless {}, $class;
}

sub create_picture {
    my ($self, $zone) = @_;
    # Use true colors
    if ($GD::VERSION >= 2.0) {
	GD::Image->trueColor(1);
    }
    my $i = new GD::Image($zone->external_width(), $zone->external_height());
    my $p = { "img" => $i, "zone" => $zone, colors => {} };
    return $p;
}

sub line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    $p->{'img'}->line( _convert_coord($p, $x1, $y1),
                       _convert_coord($p, $x2, $y2),
                       _get_color($p, $color) );
}

sub antialiased_line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    if ($GD::VERSION >= 2.0) {
	$p->{'img'}->setAntiAliased(_get_color($p, $color));
	$p->{'img'}->line( _convert_coord($p, $x1, $y1),
			   _convert_coord($p, $x2, $y2),
			   gdAntiAliased );
    } else {
	line(@_);
    }
}

sub dashed_line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    $p->{'img'}->dashedLine( _convert_coord($p, $x1, $y1),
			     _convert_coord($p, $x2, $y2),
			     _get_color($p, $color) );
}

sub line_width {
    my ($self, $p, $width) = @_;
    my $old = GT::Graphics::Driver::line_width(@_);
    if ($GD::VERSION >= 2.0) {
	if (defined $width) {
	    $p->{'img'}->setThickness($width);
	}
    }
    return $old;
}

sub rectangle {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    $p->{'img'}->rectangle( _convert_coord($p, $x1, $y2),
			    _convert_coord($p, $x2, $y1),
			    _get_color($p, $color) );
}

sub filled_rectangle {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    $p->{'img'}->filledRectangle( _convert_coord($p, $x1, $y2),
				  _convert_coord($p, $x2, $y1),
				  _get_color($p, $color) );
}

sub polygon {
    my ($self, $p, $color, @points) = @_;
    my $polygon = new GD::Polygon;

    if(scalar(@points)) {
	for (my $i = 0; $i < scalar(@points); $i++) {
	    $polygon->addPt(_convert_coord($p, $points[$i][0], $points[$i][1]));
	}
	$p->{'img'}->polygon($polygon, _get_color($p, $color));
    }
}

sub filled_polygon {
    my ($self, $p, $color, @points) = @_;
    my $polygon = new GD::Polygon;

    if(scalar(@points)) {
        for (my $i = 0; $i < scalar(@points); $i++) {
            $polygon->addPt(_convert_coord($p, $points[$i][0], $points[$i][1]));
        }
        $p->{'img'}->filledPolygon($polygon, _get_color($p, $color));
    }
}

sub circle {
    my ($self, $p, $x, $y, $width, $height, $color) = @_;
    $p->{'img'}->arc( _convert_coord($p, $x, $y),
                      $width, $height,
		      0, 360, _get_color($p, $color));
}

sub string {
    my ($self, $p, $name, $size, $color, $x, $y, $text, $halign,
	$valign, $orientation) = @_;
    my ($offset_x, $offset_y) = (0, 0);
    $halign = $ALIGN_CENTER if (! defined($halign));
    $valign = $ALIGN_BOTTOM if (! defined($valign));
    $orientation = $ORIENTATION_RIGHT if (! defined($orientation));
    my @b = GD::Image->stringTTF( _get_color($p, $color), $name, $size, 
				  $orientation, 0, 0, $text);
    die "Can't generate text : $@" if (! scalar(@b));
    if ($orientation eq $ORIENTATION_UP) {
	($halign eq $ALIGN_CENTER) && ($offset_x = int(($b[0] - $b[6]) / 2));
	($halign eq $ALIGN_LEFT)   && ($offset_x = $b[0] - $b[6]);
	($halign eq $ALIGN_RIGHT)  && ($offset_x = 0);
	($valign eq $ALIGN_CENTER) && ($offset_y = int(($b[1] - $b[3]) /2));
	($valign eq $ALIGN_TOP)    && ($offset_y = $b[1] - $b[3]);
	($valign eq $ALIGN_BOTTOM) && ($offset_y = 0);
    } elsif ($orientation eq $ORIENTATION_DOWN) {
	($halign eq $ALIGN_CENTER) && ($offset_x = int(($b[0] - $b[6]) / 2));
	($halign eq $ALIGN_LEFT)   && ($offset_x = 0);
	($halign eq $ALIGN_RIGHT)  && ($offset_x = $b[0] - $b[6]);
	($valign eq $ALIGN_CENTER) && ($offset_y = int(($b[1] - $b[3]) / 2));
	($valign eq $ALIGN_TOP)    && ($offset_y = 0);
	($valign eq $ALIGN_BOTTOM) && ($offset_y = $b[1] - $b[3]);
    } elsif ($orientation eq $ORIENTATION_LEFT) {
	($halign eq $ALIGN_CENTER) && ($offset_x = int(($b[0] - $b[2]) / 2));
	($halign eq $ALIGN_LEFT)   && ($offset_x = $b[0] - $b[2]);
	($halign eq $ALIGN_RIGHT)  && ($offset_x = 0);
	($valign eq $ALIGN_CENTER) && ($offset_y = int(($b[1] - $b[7]) / 2));
	($valign eq $ALIGN_TOP)    && ($offset_y = 0);
	($valign eq $ALIGN_BOTTOM) && ($offset_y = $b[1] - $b[7]);
    } elsif ($orientation eq $ORIENTATION_RIGHT) {
	($halign eq $ALIGN_CENTER) && ($offset_x = int(($b[0] - $b[2]) / 2));
	($halign eq $ALIGN_LEFT)   && ($offset_x = 0);
	($halign eq $ALIGN_RIGHT)  && ($offset_x = $b[0] - $b[2]);
	($valign eq $ALIGN_CENTER) && ($offset_y = int(($b[1] - $b[7]) / 2));
	($valign eq $ALIGN_TOP)    && ($offset_y = $b[1] - $b[7]);
	($valign eq $ALIGN_BOTTOM) && ($offset_y = 0);
    }
    my ($nx, $ny) = _convert_coord($p, $x, $y);
    $p->{'img'}->stringFT( _get_color($p, $color), $name, $size,
			    $orientation, $nx + $offset_x, $ny + $offset_y,
			    $text);
}

# OUTPUT FUNCTIONS
sub save_to {
    my ($self, $p, $filename) = @_;
    open(FILE, "> $filename") || die "Can't write in $filename : $!\n";
    binmode FILE;
    print FILE $p->{'img'}->png;
    close FILE;
}

sub dump {
    my ($self, $p) = @_;
    binmode STDOUT;
    print $p->{'img'}->png;
}

# PRIVATE FUNCTIONS
sub _get_color {
    my ($p, $color) = @_;
    if ($GD::VERSION >= 2.0) {
	my $color_name = "@{$color}";
	if (! exists $p->{'colors'}{$color_name}) {
	    if (scalar @{$color} > 3) {
		$p->{'colors'}{$color_name} = $p->{'img'}->colorAllocateAlpha(@{$color});
	    } else {
		$p->{'colors'}{$color_name} = $p->{'img'}->colorResolve(@{$color});
	    }
	}
	return $p->{'colors'}{$color_name};
    } else {
	return $p->{'img'}->colorResolve(@{$color}[0..2]);
    }
}

sub _convert_coord {
    my ($p, $x, $y) = @_;
    return ($x, $p->{'zone'}->external_height() - $y - 1);
}

1;
