package GT::Graphics::Object::Histogram;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);
@ISA = qw(GT::Graphics::Object);

use GT::Prices;
use GT::Graphics::Object;
use GT::Graphics::Driver;
use GT::Graphics::Tools qw(:color);
use GT::Conf;
use GT::Graphics::DataSource::GenericIndicatorResults;

GT::Conf::default("Graphic::Histogram::Color", "yellow");

=head1 GT::Graphics::Object::Histogram

This graphical object display an histogram.

=cut

sub init {
    my ($self, $calc) = @_;

    # Default values ...
    $self->{'fg_color'} = GT::Conf::get("Graphic::Histogram::Color");
    $self->{'color_ds'} = undef;

    if (defined($calc)) {
      $self->{'calc'} = $calc;
    }

    if (defined($calc) && $self->{'fg_color'} =~ /^Indicators/) {
      $self->{'color_ds'} = GT::Graphics::DataSource::GenericIndicatorResults->new($calc, $self->{'fg_color'});
    }
    else {
      $self->{'fg_color'} = get_color($self->{'fg_color'});
    }

}

=head2 $hist->set_color_datasource($ds)

Use the indicated datasource to retrieve the color of the bar.

=cut
sub set_color_datasource {
    my ($self, $color_ds) = @_;
    $self->{'color_ds'} = $color_ds;
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
		$scale->convert_to_x_coordinate($start);
    $space = 2 if ($space < 2);
    my $y_zero = $scale->convert_to_y_coordinate(0);
    $y_zero = 0 if ($y_zero < 0);
    my $color = $self->{'fg_color'};
    
    for(my $i = $start; $i <= $end; $i++)
    {
	next if (! $self->{'source'}->is_available($i));
	my @data = $self->{'source'}->get($i);
	my $y = $scale->convert_to_y_coordinate($data[0]);
	my $x = $scale->convert_to_x_coordinate($i);
	if ($self->{'fg_color'} =~ /^Indicators/ && defined($self->{'color_ds'})) {
	    $color = get_color($self->{'color_ds'}->get($i));

	    #print STDERR ">>>" . $color . "\n";
	}
	my $tooshort = 0;
	if ($y > $zone->height) {
	  $y = $zone->height;
	  $tooshort = 1;
	}
	if ($y > $y_zero) {
	    $driver->filled_rectangle($picture, 
		$zone->absolute_coordinate($x, $y_zero),
		$zone->absolute_coordinate($x + $space - 2, $y),
		$color);
	} else {
	    $driver->filled_rectangle($picture, 
		$zone->absolute_coordinate($x, $y),
		$zone->absolute_coordinate($x + $space - 2, $y_zero),
		$color);
	}

	if ( $tooshort == 1 ) {
	    my $inverse = [];
	    foreach ( 0..$#$color ) {
	        $inverse->[$_] = 255 - $color->[$_]
		  unless ($_ > 2);
	    }
	    my @points = (
		[$zone->absolute_coordinate($x + int($space / 2) - 1, $y) ],
		[$zone->absolute_coordinate($x, $y - $space) ],
		[$zone->absolute_coordinate($x + $space - 2, $y - $space) ]
	    );
	    $driver->filled_polygon($picture, $inverse, @points);
	}
    }
}


sub set_foreground_color {
    my ($self, $color) = @_;
    if ( $self->{'calc'} ne "" && $color =~ /^Indicators/) {
      $self->{'fg_color'} = $color;
      $self->{'color_ds'} = GT::Graphics::DataSource::GenericIndicatorResults->new($self->{'calc'}, $color );
    }
    else {
      $self->{'fg_color'} = get_color($color);
    }
}


1;
