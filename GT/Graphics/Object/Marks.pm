package GT::Graphics::Object::Marks;

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

GT::Conf::default("Graphic::Marks::Color", "green");
GT::Conf::default("Graphic::Marks::Width", 4);

=head1 GT::Graphics::Object::Marks

This graphical object display a serie of marks.

=cut

sub init {
    my ($self) = @_;
    
    # Default values ...
    $self->{'fg_color'} = get_color(GT::Conf::get("Graphic::Marks::Color"));
    $self->{'width'} = GT::Conf::get("Graphic::Marks::Width");
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my $width = $self->{'width'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my ($space) = int(($scale->convert_to_x_coordinate($start + 1) -
	          $scale->convert_to_x_coordinate($start) - $width - 1) / 2);
    for(my $i = $start; $i <= $end; $i++)
    {
	next if (! $self->{'source'}->is_available($i));
	my $data = $self->{'source'}->get($i);
	my ($x, $y) = $scale->convert_to_coordinate($i, $data);
	next if (! $zone->includes_point($x + int($width / 2), $y));
	$x += $space;
	$driver->line($picture,
	    $zone->absolute_coordinate($x, $y),
	    $zone->absolute_coordinate($x + $width, $y),
	    $self->{'fg_color'});
	$driver->line($picture,
	    $zone->absolute_coordinate($x + int($width / 2), $y - int($width / 2)),
	    $zone->absolute_coordinate($x + int($width / 2), $y + int($width / 2)),
	    $self->{'fg_color'});
    }
}

1;
