package GT::Graphics::Driver::SVG;

# Copyright 2000-2004 Raphaël Hertzog, Fabien Fulhaber, Olivr Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use GT::Graphics::Driver;
use GT::Graphics::Zone;
use SVG;

our @ISA = qw(GT::Graphics::Driver);

=head1 GT::Graphics::Driver::SVG

=head2 Overview

This driver implements the drawing primitives using the SVG module available in CPAN to create Scalable Vector Graphics (SVG) files,
which is an exciting new XML-based language for Web graphics from the World Wide Web Consortium (W3C).

=head2 Links

http://www.adobe.com/svg/main.html
http://www.w3.org/TR/SVG/
http://www.roasp.com/

=cut

# PUBLIC DRIVER INTERFACE
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    return bless {}, $class;
}

sub create_picture {
    my ($self, $zone) = @_;
    my $i = SVG->new(width=>$zone->external_width(), 
		     height=>$zone->external_height());
    my $p = { "img" => $i,
	      "zone" => $zone,
	      "linewidth" => 1,
	      'stroke-opacity' => 1,
	      'fill-opacity' => 1
	    };
    return $p;
}

sub line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y1);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y2);
    
    $p->{'img'}->line(x1=>$xpt1, y1=>$ypt1, x2=>$xpt2, y2=>$ypt2, 
		      style=>{'stroke'=> _get_color($p, $color, 0),
			      'stroke-width' => $p->{linewidth},
			      'stroke-opacity' => $p->{'stroke-opacity'},
			     });
}

sub dashed_line {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y1);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y2);

    $p->{'img'}->line(x1=>$xpt1, y1=>$ypt1, x2=>$xpt2, y2=>$ypt2, 
		      style=>{'stroke'=> _get_color($p, $color, 0), 
			      'stroke-dasharray'=>5,
			      'stroke-width' => $p->{linewidth},
			      'stroke-opacity' => $p->{'stroke-opacity'},
			     });
}

sub rectangle {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y2);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y1);

    $p->{'img'}->rectangle(x=>$xpt1, y=>$ypt1, width=>abs($xpt1 - $xpt2),
			   height=>abs($ypt1 - $ypt2),
                           style=>{'fill'=>'none', 
				   'stroke'=>_get_color($p, $color, 0),
				   'stroke-width' => $p->{linewidth},
				   'stroke-opacity' => $p->{'stroke-opacity'},
				  });
}

sub filled_rectangle {
    my ($self, $p, $x1, $y1, $x2, $y2, $color) = @_;
    my ($xpt1, $ypt1) = _convert_coord($p, $x1, $y2);
    my ($xpt2, $ypt2) = _convert_coord($p, $x2, $y1);

    $p->{'img'}->rectangle(x=>$xpt1, y=>$ypt1, width=>abs($xpt1 - $xpt2),
			   height=>abs($ypt1 - $ypt2),
                           style=>{'fill'=>_get_color($p, $color, 1),
				   'stroke'=>_get_color($p, $color, 0),
				   'stroke-width' => $p->{linewidth},
				   'stroke-opacity' => $p->{'stroke-opacity'},
				   'fill-opacity' => $p->{'fill-opacity'}
				  });
}

sub polygon {
    my ($self, $p, $color, @points) = @_;
    my ($xv, $yv);

    if(scalar(@points)) {
        for (my $i = 0; $i < scalar(@points); $i++) {
            my ($x, $y) = _convert_coord($p, $points[$i][0], $points[$i][1]);
            push(@{$xv}, $x);
            push(@{$yv}, $y);
        }
    }

    my $points = $p->{'img'}->get_path(x=>$xv, y=>$yv, -type=>'polygon');
    $p->{'img'}->polygon(%$points, style=>{'stroke'=>_get_color($p, $color, 0), 
					   'fill'=>'none',
					   'stroke-width' => $p->{linewidth},
					   'stroke-opacity' => $p->{'stroke-opacity'},
					  });
}

sub filled_polygon {
    my ($self, $p, $color, @points) = @_;
    my ($xv, $yv);

    if(scalar(@points)) {
	for (my $i = 0; $i < scalar(@points); $i++) {
	    my ($x, $y) = _convert_coord($p, $points[$i][0], $points[$i][1]);
	    push(@{$xv}, $x);
	    push(@{$yv}, $y);
	}
    }
    
    my $points = $p->{'img'}->get_path(x=>$xv, y=>$yv, -type=>'polygon');
    $p->{'img'}->polygon(%$points, style=>{'stroke'=>_get_color($p, $color, 0), 
					   'fill'=>_get_color($p, $color, 1),
					   'stroke-width' => $p->{linewidth},
					   'stroke-opacity' => $p->{'stroke-opacity'},
					   'fill-opacity' => $p->{'fill-opacity'}
					  });
}

sub circle {
    my ($self, $p, $x, $y, $width, $height, $color) = @_;

    my ($cx, $cy) = _convert_coord($p, (($x + $width) / 2), 
				       (($y + $height) / 2));
    my $rx = $width / 2;
    my $ry = $height / 2;

    $p->{'img'}->circle(id=>'circle', cx=>$cx, cy=>$cy, rx=>$rx, ry=>$ry,
		    style=>{'stroke'=>_get_color($p, $color,0), 
			    'fill'=>'none',
			    'stroke-width' => $p->{linewidth},
			    'stroke-opacity' => $p->{'stroke-opacity'},
			   });
}

sub filled_circle {
    my ($self, $p, $x, $y, $width, $height, $color) = @_;

    my ($cx, $cy) = _convert_coord($p, (($x + $width) / 2), 
				       (($y + $height) / 2));
    my $rx = $width / 2;
    my $ry = $height / 2;

    $p->{'img'}->circle(id=>'circle', cx=>$cx, cy=>$cy, rx=>$rx, ry=>$ry,
			style=>{'fill'=>_get_color($p, $color, 1),
				'stroke'=>_get_color($p, $color, 0),
				'stroke-width' => $p->{linewidth},
				'stroke-opacity' => $p->{'stroke-opacity'},
				'fill-opacity' => $p->{'fill-opacity'}
			       });
}

sub string {
    my ($self, $p, $name, $size, $color, $x, $y, $text, $halign,
	$valign, $orientation) = @_;
    my ($offset_x, $offset_y) = (0, 0);
    my ($nx, $ny) = _convert_coord($p, $x, $y);

    $name = "Serif";
    $name = "Arial" if ($name =~ /arial/i );

    my $anchor = "middle";
    $anchor = "start" if ($halign eq $ALIGN_LEFT);
    $anchor = "end" if ($halign eq $ALIGN_RIGHT);

    my $baseshift = 0;
    $baseshift = $size if ($valign eq $ALIGN_BOTTOM);
    $baseshift = -$size if ($valign eq $ALIGN_TOP);

    # Not yet implemented. Feel free to do it yourself ! :)
    $p->{'img'}->text(x=>$nx, 
		      y=>$ny,
                      style=>{
                         'font-size'=>$size,
		         'font-family'=>$name,
		         'stroke-width' => $p->{linewidth},
		         'stroke-opacity' => $p->{'stroke-opacity'},
		         'fill-opacity' => $p->{'fill-opacity'},
		         'text-anchor' => $anchor,
		       },
		       'fill'=>_get_color($p, $color, 1))
                         ->tspan('baseline-shift' => $baseshift)->cdata($text);
}

# OUTPUT FUNCTIONS
sub save_to {
    my ($self, $p, $filename) = @_;
    open(FILE, "> $filename") || die "Can't write in $filename : $!\n";
    binmode FILE;
    print FILE $p->{'img'}->xmlify;
    close FILE;
}

sub dump {
    my ($self, $p) = @_;
    binmode STDOUT;
    print $p->{'img'}->xmlify;
}

# PRIVATE FUNCTIONS
sub _get_color {
    my ($p, $color, $fill) = @_;
    if ( $#{$color} == 3 ) {
      my ($red, $green, $blue, $alpha) = @{$color};
      if ( !defined($fill) || $fill == 1 ) {
	$p->{'fill-opacity'} = $alpha / 255;
      } else {
	$p->{'stroke-opacity'} = $alpha / 255;
      }
      return 'rgb(' . $red . ',' . $green . ',' . $blue . ')';
    }

    my ($red, $green, $blue) = @{$color};
    $p->{'stroke-opacity'} = 1;
    $p->{'fill-opacity'} = 1;
    return 'rgb(' . $red . ',' . $green . ',' . $blue . ')';
}

sub _convert_coord {
    my ($p, $x, $y) = @_;
    return ($x, $p->{'zone'}->external_height() - $y - 1);
}

1;
