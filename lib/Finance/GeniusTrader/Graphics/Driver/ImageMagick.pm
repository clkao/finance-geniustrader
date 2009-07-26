package GT::Graphics::Driver::ImageMagick;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use GT::Graphics::Driver;
use GT::Graphics::Zone;
use Image::Magick;

our @ISA = qw(GT::Graphics::Driver);

=head1 GT::Graphics::Driver::ImageMagick

This driver implements the drawing primitives using the ImageMagick Perl extension.

=cut

# PUBLIC DRIVER INTERFACE
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    return bless {}, $class;
}

sub create_picture {
    my ($self, $zone) = @_;
    my $size = $zone->external_width() . 'x' . $zone->external_height();
    my $i = Image::Magick->new(size=>$size);
    $i->ReadImage('xc:white');
    my $p = { "img" => $i, "zone" => $zone, "linewidth" => 1 };
    return $p;
}

sub line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y1);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y2);
    my $points = $xpt1 . ',' . $ypt1 . ' ' . $xpt2 . ',' . $ypt2;
    $p->{'img'}->Draw(fill=>_get_color($p, $color), antialias=>0, primitive=>'line', points=>$points, strokewidth=>$p->{'linewidth'});
}

sub antialiased_line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y1);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y2);
    my $points = $xpt1 . ',' . $ypt1 . ' ' . $xpt2 . ',' . $ypt2;
    $p->{'img'}->Draw(fill=>_get_color($p, $color), antialias=>1, primitive=>'line', points=>$points, strokewidth=>$p->{'linewidth'});
}

sub dashed_line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    
    # Not yet implemented
}

sub rectangle {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y1);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y2);
    my $points = $xpt1 . ',' . $ypt1 . ' ' . $xpt2 . ',' . $ypt2;
    $p->{'img'}->Draw(stroke=>_get_color($p, $color), primitive=>'rectangle', points=>$points, fill=>'none', strokewidth=>$p->{'linewidth'});
}

sub filled_rectangle {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y1);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y2);
    my $points = $xpt1 . ',' . $ypt1 . ' ' . $xpt2 . ',' . $ypt2;
    $p->{'img'}->Draw(fill=>_get_color($p, $color), bordercolor=>_get_color($p, $color), stroke=>_get_color($p, $color), primitive=>'rectangle', points=>$points);
}

sub polygon {
    my ($self, $p, $color, @points) = @_;
    my $data;

    if(scalar(@points)) {
	for (my $i = 0; $i < scalar(@points); $i++) {
	    my ($x1, $x2) = _convert_coord($p, $points[$i][0], $points[$i][1]);
	    $data .= $x1 . ',' . $x2;
	    $data .= ' ' if ($i != (scalar(@points) - 1));
	}
	$p->{'img'}->Draw(stroke=>_get_color($p, $color), primitive=>'polygon', points=>$data, fill=>'none', strokewidth=>$p->{'linewidth'});
    }
}

sub filled_polygon {
    my ($self, $p, $color, @points) = @_;
    my $data;

    if(scalar(@points)) {
        for (my $i = 0; $i < scalar(@points); $i++) {
	    my ($x1, $x2) = _convert_coord($p, $points[$i][0], $points[$i][1]);
            $data .= $x1 . ',' . $x2;
            $data .= ' ' if ($i != (scalar(@points) - 1));
        }
        $p->{'img'}->Draw(fill=>_get_color($p, $color), bordercolor=>_get_color($p, $color), stroke=>_get_color($p, $color), primitive=>'polygon', points=>$data);
    }
}

sub circle {
    my ($self, $p, $x, $y, $width, $height, $color) = @_;

    my ($x_, $y_) = _convert_coord($p, $x, $y);
    $width = int($width/2);
    $height = int($height/2);
    my $data = "$x_,$y_ $width,$height 0,360";
    $p->{'img'}->Draw(stroke=>_get_color($p, $color), primitive=>'ellipse', points=>$data, fill=>'none', strokewidth=>$p->{'linewidth'});
}

sub string {
    my ($self, $p, $name, $size, $color, $x, $y, $text, $halign,
	$valign, $orientation) = @_;
    my ($offset_x, $offset_y) = (0, 0);
    $halign = $ALIGN_CENTER if (! defined($halign));
    $valign = $ALIGN_BOTTOM if (! defined($valign));
    $orientation = $ORIENTATION_RIGHT if (! defined($orientation));

    my $rotate = 0;
    $rotate = 90 if ($orientation eq $ORIENTATION_DOWN);
    $rotate = -90 if ($orientation eq $ORIENTATION_UP);
    
    my ($character_width, $character_height, $ascender, $descender, $text_width, $text_height, $maximum_horizontal_advance) = 
    $p->{'img'}->QueryFontMetrics(font=>$name, pointsize=>$size, fill=>_get_color($p, $color), text=>$text, rotate=>$rotate, antialias=>'true');

    #die "Can't generate text : $@" if (! scalar(@b));
    if ($orientation eq $ORIENTATION_UP) {
	#($halign eq $ALIGN_CENTER) && ($offset_y = );
	#($halign eq $ALIGN_LEFT)   && ($offset_y = );
	#($halign eq $ALIGN_RIGHT)  && ($offset_y = );
	#($valign eq $ALIGN_CENTER) && ($offset_x = );
	#($valign eq $ALIGN_TOP)    && ($offset_x = );
	#($valign eq $ALIGN_BOTTOM) && ($offset_x = );
    } elsif ($orientation eq $ORIENTATION_DOWN) {
	($halign eq $ALIGN_CENTER) && ($offset_y = -int($text_width / 2));
	($halign eq $ALIGN_LEFT)   && ($offset_y = -$text_width);
	($halign eq $ALIGN_RIGHT)  && ($offset_y = 0);
	($valign eq $ALIGN_CENTER) && ($offset_x = -$text_height - int($text_height / 2));
	($valign eq $ALIGN_TOP)    && ($offset_x = -$text_height);
	($valign eq $ALIGN_BOTTOM) && ($offset_y = -$text_height - $text_height);
    } elsif ($orientation eq $ORIENTATION_LEFT) {
	#($halign eq $ALIGN_CENTER) && ($offset_x = );
	#($halign eq $ALIGN_LEFT)   && ($offset_x = );
	#($halign eq $ALIGN_RIGHT)  && ($offset_x = );
	#($valign eq $ALIGN_CENTER) && ($offset_y = );
	#($valign eq $ALIGN_TOP)    && ($offset_y = );
	#($valign eq $ALIGN_BOTTOM) && ($offset_y = );
    } elsif ($orientation eq $ORIENTATION_RIGHT) {
	($halign eq $ALIGN_CENTER) && ($offset_x = -int($text_width / 2));
	($halign eq $ALIGN_LEFT)   && ($offset_x = 0);
	($halign eq $ALIGN_RIGHT)  && ($offset_x = -$text_width);
	($valign eq $ALIGN_CENTER) && ($offset_y = int($text_height / 2));
	($valign eq $ALIGN_TOP)    && ($offset_y = $text_height);
	($valign eq $ALIGN_BOTTOM) && ($offset_y = 0);
    }
    my ($nx, $ny) = _convert_coord($p, $x, $y);
    $p->{'img'}->Annotate(font=>$name, pointsize=>$size, fill=>_get_color($p, $color), text=>$text, x=>$nx + $offset_x, y=>$ny + $offset_y, rotate=>$rotate, antialias=>'true');
}

# OUTPUT FUNCTIONS
sub save_to {
    my ($self, $p, $filename) = @_;
    $p->{'img'}->Write(filename=>$filename, compression=>'None');
}

sub dump {
    my ($self, $p) = @_;
    binmode STDOUT;
    $p->{'img'}->Write('png:-');
}

# PRIVATE FUNCTIONS
sub _get_color {
    my ($p, $color) = @_;
    my ($red, $green, $blue) = @{$color};
    my $alpha = 0;
    $alpha = $color->[3] if ($#{$color}>=3);
    my $coln = sprintf ("#%02X%02X%02X%02X", $red, $green, $blue, $alpha);
    return $coln;
}

sub _convert_coord {
    my ($p, $x, $y) = @_;
    return ($x, $p->{'zone'}->external_height() - $y - 1);
}

1;
