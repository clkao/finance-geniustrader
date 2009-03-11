package GT::Graphics::Object::Polygon;

# Copyright 2003 Oliver Bossert
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

GT::Conf::default("Graphic::Polygon::Color", "red");

=head1 GT::Graphics::Object::Text

This graphical object displays a block of text.

=cut

sub init {
    my $self = shift;
    #my $calc = shift;
    my $pts = shift;
    my @points = @{$pts};
    print STDERR join("#", @points) . "\n";
    my @realpoints = ();
    for (my $i=0; $i<=$#points; $i++) {
      my ($day, $val) = split /\//, $points[$i];
      if ( $day =~ /....-..-../ ) {
	if ($self->{'source'}->prices->has_date($day)) {
	    $day = $self->{'source'}->prices->date($day);
	} else {
	    $day = $self->{'source'}->prices->date($self->{'source'}->prices->find_nearest_date($day));
	}
      }
      push @realpoints, [$day, $val];
      print STDERR $day . " - " . $val . "\n";
    }
    push @realpoints, [$realpoints[0][0], $realpoints[0][1]];
    $self->{'points'} = \@realpoints;
    $self->{'fg_color'} = get_color(GT::Conf::get("Graphic::Polygon::Color"));
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $zone = $self->{'zone'};
    my $scale = $self->get_scale();

    my @points = @{$self->{'points'}};
    for (my $i=0; $i<=$#points; $i++) {
      ($points[$i][0], $points[$i][1]) = $zone->absolute_coordinate($scale->convert_to_x_coordinate($points[$i][0]),
								    $scale->convert_to_y_coordinate($points[$i][1]));
    }

    $self->{filled} ? 
        $driver->filled_polygon($picture, $self->{'fg_color'}, @points)
      : $driver->polygon($picture, $self->{'fg_color'}, @points);
}

1;
