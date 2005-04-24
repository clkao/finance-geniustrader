package GT::Graphics::Driver;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use GT::Conf;

use vars qw(@EXPORT @ISA

	     $FONT_SIZE_TINY $FONT_SIZE_SMALL $FONT_SIZE_MEDIUM
	     $FONT_SIZE_LARGE $FONT_SIZE_GIANT
	     
	     $FONT_ARIAL $FONT_TIMES $FONT_HELVETICA
	     $FONT_SANS_SERIF $FONT_FIXED $FONT_PROPORTIONNAL $FONT_SERIF
	     
	     $ALIGN_LEFT $ALIGN_CENTER $ALIGN_RIGHT $ALIGN_TOP $ALIGN_BOTTOM

	     $ORIENTATION_UP $ORIENTATION_DOWN $ORIENTATION_LEFT
	     $ORIENTATION_RIGHT

	     $COLOR_WHITE $COLOR_BLACK $COLOR_RED $COLOR_GREEN $COLOR_BLUE
	   );

require Exporter;
@ISA = qw(Exporter);
@EXPORT = qw(
	     $FONT_SIZE_TINY $FONT_SIZE_SMALL $FONT_SIZE_MEDIUM
	     $FONT_SIZE_LARGE $FONT_SIZE_GIANT
	     
	     $FONT_ARIAL $FONT_TIMES $FONT_HELVETICA
	     $FONT_SANS_SERIF $FONT_FIXED $FONT_PROPORTIONNAL $FONT_SERIF

	     $ALIGN_LEFT $ALIGN_CENTER $ALIGN_RIGHT $ALIGN_TOP $ALIGN_BOTTOM

	     $ORIENTATION_UP $ORIENTATION_DOWN $ORIENTATION_LEFT
	     $ORIENTATION_RIGHT

	     $COLOR_WHITE $COLOR_BLACK $COLOR_RED $COLOR_GREEN $COLOR_BLUE
	    );

GT::Conf::load();

$FONT_SIZE_TINY   = 8;
$FONT_SIZE_SMALL  = 12;
$FONT_SIZE_MEDIUM = 14;
$FONT_SIZE_LARGE  = 18;
$FONT_SIZE_GIANT  = 30;

$FONT_ARIAL = GT::Conf::get("Path::Font::Arial");
$FONT_TIMES = GT::Conf::get("Path::Font::Times");
$FONT_HELVETICA = GT::Conf::get("Path::Font::Arial");
$FONT_SANS_SERIF = GT::Conf::get("Path::Font::Arial");
$FONT_FIXED = GT::Conf::get("Path::Font::Courier");
$FONT_PROPORTIONNAL = GT::Conf::get("Path::Font::Times");
$FONT_SERIF = GT::Conf::get("Path::Font::Times");

$ALIGN_LEFT = "left";
$ALIGN_CENTER = "center";
$ALIGN_RIGHT = "right";
$ALIGN_TOP = "top";
$ALIGN_BOTTOM = "bottom";

$ORIENTATION_UP = 3.1415 / 2;
$ORIENTATION_DOWN = - 3.1415 / 2;
$ORIENTATION_RIGHT = 0;
$ORIENTATION_LEFT = - 3.1415;

$COLOR_WHITE = [ 255, 255, 255, 0 ];
$COLOR_BLACK = [ 0, 0, 0, 0 ];
$COLOR_RED =   [ 255, 0, 0, 0 ];
$COLOR_GREEN = [ 0, 255, 0, 0 ];
$COLOR_BLUE =  [ 0, 0, 255, 0 ];


=head1 GT::Graphics::Driver

A graphic driver is a well defined interface that let you actually
generate a picture by using drawing primitives. Those primitives
are used by "drawable" objects that implements the
display($driver, $picture) method.

=head1 Drawing API

=head2 $picture = $driver->create_picture($rootzone)

This does create the empty picture on which you'll draw various things.
The picture has the size corresponding to the given "zone".

=head2 $driver->line($picture, $x1, $y1, $x2, $y2, $color)

=head2 $driver->dashed_line($picture, $x1, $y1, $x2, $y2, $color)

=head2 $driver->antialiased_line($picture, $x1, $y1, $x2, $y2, $color)

=cut
sub antialiased_line {
    my $self = shift;
    $self->line(@_);
}

=head2 $driver->rectangle($picture, $x1, $y1, $x2, $y2, $color)

=head2 $driver->filled_rectangle($picture, $x1, $y1, $x2, $y2, $color)

=head2 $driver->polygon($picture, $color, @points)

=head2 $driver->filled_polygon($picture, $color, @points)

=head2 $driver->circle($picture, $x, $y, $width, $height, $color)

The last 7 methods are simple drawing methods. The coordinates are
absolute (ie as expressed in the $rootzone). Take care to convert
them if needed.

For the rectangles, you give the lower left corner and the upper
right corner.

The (0,0) coordinate is the lower left corner.

=head2 my $oldwidth  = $driver->line_width($picture, $width)

This method changes the default width of displayed lines. It returns the
previous width so that you can restore it to its previous value once
you're finished with the operation needing a special line width.

If $width isn't given, it only returns the actual width.

=cut
sub line_width {
    my ($self, $picture, $width) = @_;
    if (! exists $picture->{'linewidth'}) {
	$picture->{'linewidth'} = 1;
    }
    my $old = $picture->{'linewidth'};
    if (defined $width) {
	$picture->{'linewidth'} = $width;
    }
    return $old;
}

=head2 $driver->string($p, $name, $size, $color, $x, $y, $text, $halign, $valign, $orientation)

This method is used to draw texts on the picture. 

Horizontal/vertical align : $ALIGN_LEFT, $ALIGN_CENTER, $ALIGN_RIGHT

Orientation : $ORIENTATION_UP, $ORIENTATION_DOWN, $ORIENTATION_RIGHT, $ORIENTATION_LEFT

The text is displayed near (x,y) by follwing the required alignments.

=head1 Output API

=head2 $driver->save_to($p, $filename)

Save the picture in the given filename.

=head2 $driver->dump($p)

Dump the picture to the standard output.

=head1 Generic functions

Those functions don't need to be reimplemented, they are implemented with the
other primitives.

=head2 $driver->cross($picture, $x1, $y1, $x2, $y2, $color)

Draw a cross.

=cut
sub cross {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    $self->line($p, $x1, $y1, $x2, $y2, $color);
    $self->line($p, $x1, $y2, $x2, $y1, $color);
}   

=head1 DATA STRUCTURE

=head2 Colors

Colors are simple RGB triplet associated to an alpha channel : [ R, G, B, A ]
They are only array references.

Some variables are available for the most common colors :

=over

=item $COLOR_WHITE

=item $COLOR_BLACK

=item $COLOR_RED

=item $COLOR_GREEN

=item $COLOR_BLUE

=back

=head2 Fonts

Font names are simple strings (true type font names). Font size are numbers.

Some variables are available for the most common values :

=over

=item $FONT_SIZE_TINY

=item $FONT_SIZE_SMALL

=item $FONT_SIZE_MEDIUM

=item $FONT_SIZE_LARGE

=item $FONT_SIZE_GIANT

=back

=over

=item $FONT_ARIAL

=item $FONT_TIMES

=item $FONT_HELVETICA

=item $FONT_SERIF

=item $FONT_SANS_SERIF

=item $FONT_FIXED

=item $FONT_PROPORTIONNAL

=back

=cut

1;
