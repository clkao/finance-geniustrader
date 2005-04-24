package GT::Graphics::Graphic;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

use GT::Graphics::Driver;
use GT::Graphics::Zone;
use GT::Graphics::Tools qw(:color);
use GT::Conf;

GT::Conf::default("Graphic::BackgroundColor", "white");
GT::Conf::default("Graphic::ForegroundColor", "black");

=head1 GT::Graphics::Graphic

A graphic is composed of a layout of zones. Objects are affected to
the various zones. Those objects may be displayed. The display engine
may use an associated default scale to obtain coordinates of points to
draw.

=cut

=head2 GT::Graphics::Graphic->new($zone)

Create a new graphic using the specified zone layout.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $zone = shift;
    
    my $self = { "zone" => $zone, "objects" => [],
		 "bg_color" => 
			get_color(GT::Conf::get("Graphic::BackgroundColor")),
		 "fg_color" => 
			get_color(GT::Conf::get("Graphic::ForegroundColor"))
	       };

    return bless $self, $class;
}

=head2 $graphic->set_zone($zone)

Define the layout of the display zones. You shouldn't call this once
you added graphical objects because objects may reference zones that
are no more part of the new layout.

=cut
sub set_zone {
    my ($self, $zone) = @_;
    $self->{'zone'} = $zone;
}

=head2 $graphic->set_background_color($color)

Set the background color of the graphic.

=cut
sub set_background_color {
    my ($self, $color) = @_;
    $self->{'bg_color'} = get_color($color);
}

=head2 $graphic->add_object($object)

Add a graphical object to the graphic.

=cut
sub add_object {
    my ($self, $object) = @_;
    push @{$self->{'objects'}}, $object;
    $object->set_z_level(scalar @{$self->{'objects'}});
}

=head2 $graphic->display($driver, $picture)

Display the graphic in the picture. It will display the zones and the
graphical objects.

=cut
sub display { 
    my ($self, $driver, $picture) = @_;
    my $z = $self->{'zone'};
    $driver->filled_rectangle($picture, 0, 0, $z->external_width() - 1,
			      $z->external_height() - 1,
			      $self->{'bg_color'});
    $self->{'zone'}->display($driver, $picture);
    foreach my $object (sort { $a->get_z_level() <=> $b->get_z_level() }
			     @{$self->{'objects'}}) {
	$object->display($driver, $picture);
    }
}

1;
