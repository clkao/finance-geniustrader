package Finance::GeniusTrader::Graphics::Object::Polygon;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);
@ISA = qw(Finance::GeniusTrader::Graphics::Object);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Graphics::Object;
use Finance::GeniusTrader::Graphics::Driver;
use Finance::GeniusTrader::Graphics::Tools qw(:color);
use Finance::GeniusTrader::Conf;

Finance::GeniusTrader::Conf::default("Graphic::Polygon::Color", "red");

=head1 Finance::GeniusTrader::Graphics::Object::Text

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
    $self->{'fg_color'} = get_color(Finance::GeniusTrader::Conf::get("Graphic::Polygon::Color"));
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

    $driver->polygon($picture, $self->{'fg_color'}, @points);
}

1;
