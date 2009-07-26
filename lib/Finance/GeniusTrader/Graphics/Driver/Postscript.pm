package Finance::GeniusTrader::Graphics::Driver::Postscript;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use Finance::GeniusTrader::Graphics::Driver;
use Finance::GeniusTrader::Graphics::Zone;
use PostScript::Simple;
use Finance::GeniusTrader::Conf;

our @ISA = qw(Finance::GeniusTrader::Graphics::Driver);

=head1 Finance::GeniusTrader::Graphics::Driver::Postscript

This driver implements the drawing primitives using the PostScripts::Simple-module.

=cut

# PUBLIC DRIVER INTERFACE
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    return bless {}, $class;
}

sub create_picture {
    my ($self, $zone) = @_;
    my $i = new PostScript::Simple(eps => 1,
				   colour => 1,
				   xsize => $zone->external_width(),
				   ysize => $zone->external_height(),
				   units => "pt",
				   reencode => "ISOLatin1Encoding");
    my $p = { "img" => $i, "zone" => $zone };
    return $p;
}

sub line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y1);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y2);
    Finance::GeniusTrader::Conf::default("Graphic::Linewidth", "1");
    $self->{'linewidth'} = Finance::GeniusTrader::Conf::get("Graphic::Linewidth");

    $p->{'img'}->setlinewidth( $self->{'linewidth'} );
    $p->{'img'}->line($xpt1, $ypt1, $xpt2, $ypt2, _get_color($p, $color));
}

sub antialiased_line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    $self->line($p, $x1, $y1, $x2, $y2, $color);
}

sub dashed_line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    
    # Not yet implemented
}

sub rectangle {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y1);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y2);

    $p->{'img'}->setcolour( _get_color($p, $color) );
    $p->{'img'}->box({filled=>0}, $xpt1, $ypt1, $xpt2, $ypt2);
}

sub filled_rectangle {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y1);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y2);
    $p->{'img'}->setcolour( _get_color($p, $color) );
    $p->{'img'}->box({filled=>1}, $xpt1, $ypt1, $xpt2, $ypt2);
}

sub polygon {
    my ($self, $p, $color, @points) = @_;

    my @pts = ();
    if(scalar(@points)) {
	for (my $i = 0; $i < scalar(@points); $i++) {
	    my ($x1, $x2) = _convert_coord($p, $points[$i][0], $points[$i][1]);
	    push @pts, $x1;
	    push @pts, $x2;
	}
	$p->{'img'}->setcolour( _get_color($p, $color) );
	$p->{'img'}->polygon({filled=>0}, @pts);
    }
}

sub filled_polygon {
    my ($self, $p, $color, @points) = @_;

    my @pts = ();
    if(scalar(@points)) {
	for (my $i = 0; $i < scalar(@points); $i++) {
	    my ($x1, $x2) = _convert_coord($p, $points[$i][0], $points[$i][1]);
	    push @pts, $x1;
	    push @pts, $x2;
	}
	$p->{'img'}->setcolour( _get_color($p, $color) );
	$p->{'img'}->polygon({filled=>1}, @pts);
    }
}

sub circle {
    my ($self, $p, $x, $y, $width, $height, $color) = @_;

    my ($x, $y) = _convert_coord($p, $x, $y);
    $width = int($width/2);
    $height = int($height/2);

    $p->{'img'}->setcolour( _get_color($p, $color) );
    $p->{'img'}->circle($x, $y, ($width+$height)/2);
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

    my $nname = "Times-Roman-iso";
    $nname = "Helvetica-iso" if ($name =~ /arial/);
    $p->{'img'}->setfont($nname, $size);

    if ($valign eq $ALIGN_TOP) {
      $y -= $size;
    } elsif ($valign == $ALIGN_CENTER) {
      $y -= ($size/2);
    }
    my ($nx, $ny) = _convert_coord($p, $x, $y);

    my $alg = "centre";
    if ($halign eq $ALIGN_LEFT) {
      $alg = "left";
    } elsif ($halign eq $ALIGN_RIGHT) {
      $alg = "right";
    }
    $p->{'img'}->text( { rotate => $rotate, align => $alg }, $nx, $ny, $text);
}

# OUTPUT FUNCTIONS
sub save_to {
    my ($self, $p, $filename) = @_;
    $p->{'img'}->output($filename);
}

sub dump {
    my ($self, $p) = @_;
    print $p->{'img'}->get();
}

# PRIVATE FUNCTIONS
sub _get_color {
    my ($p, $color) = @_;
    return @{$color}[0..2];
}

sub _convert_coord {
    my ($p, $x, $y) = @_;
    return ($x, $y); #$p->{'zone'}->external_height() - $y);
}

1;
