package GT::Graphics::Object;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use GT::Graphics::Graphic;
use GT::Graphics::Tools qw(:color);
use GT::Conf;

require GT::Graphics::Object::Candle;
require GT::Graphics::Object::CandleVolume;
require GT::Graphics::Object::CandleVolumePlace;
require GT::Graphics::Object::BarChart;
require GT::Graphics::Object::Histogram;
require GT::Graphics::Object::Marks;
require GT::Graphics::Object::Curve;
require GT::Graphics::Object::Mountain;
require GT::Graphics::Object::MountainBand;
require GT::Graphics::Object::Text;
require GT::Graphics::Object::Polygon;
require GT::Graphics::Object::BuySellArrows;
require GT::Graphics::Object::VotingLine;

#
# these are experimental-developmental packages that
# may not yet be in the 'offical' distribution
#
# therefore they are imported as 'use' so if they
# don't exist when this module is loaded perl will
# not complain unless the module is actually needed
#
use GT::Graphics::Object::Positions;
use GT::Graphics::Object::Trades;

=head1 GT::Graphics::Object

A graphical object is a part of a graphic. It can display itself
on a picture.

=head1 FUNCTIONS TO IMPLEMENT

Each graphic object will have to implement these two functions (methods).

=head2 $o->init(...)

This function is called with the trailing arguments (e,g, $args[2]
and up) given to the generic new constructor defined here.

=head2 $o->display($driver, $picture)

Display the graphic object on the picture using the given driver.
It may use $o->{'source'} and $o->{'zone'} (e.g. the graphic objects
argument hash $self->{'source'} and $self->{'zone'} to get the data
to display and display itself in the correct zone.

=head1 GENERIC FUNCTIONS

=head2 my $obj = GT::Graphics::Object::<Something>->new($datasource, $zone, ...)

The generic new constructor declared and defined here takes the
first 2 arguments (e.g. $datasource and $zone) and assigns them to
the objects argument hash $self->{'source'} and $self->{'zone'},
respectively, and passes the remaining arguments, if any, to the
init method which must be provided by the
GT::Graphics::Object::<Something> package.

in addition, the new constructor sets the objects argument hash
keys 'bg_color' and 'fg_color' (e.g. $self->{'bg_color'} and
$self->{'fg_color'}) to the gt config key-values corresponding with
Graphic::BackgroundColor and Graphic::ForegroundColor respectively.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $source = shift;
    my $zone = shift;

    my $self = { "source" => $source,
                 "zone" => $zone,
                 "bg_color" => 
                        get_color(GT::Conf::get("Graphic::BackgroundColor")),
                 "fg_color" => 
                        get_color(GT::Conf::get("Graphic::ForegroundColor")),
               };
    bless $self, $class;

    $self->init(@_);

    return $self;
}

=head2 my $o_z_level = $o->get_z_level()

=head2 $o->set_z_level($z)

Those two functions are used to manage the order in which the orders
are displayed. An object with a low Z level is drawn first.

=cut

sub get_z_level {
    my ($self) = @_;
    return $self->{'z'};
}

sub set_z_level {
    my ($self, $z) = @_;
    $self->{'z'} = $z;
}

=head2 my $o_datasource = $o->get_source()

=head2 $o->set_source($source)

set/get the datasource associated to this object.

=cut

sub set_source {
    my ($self, $source) = @_;
    $self->{'source'} = $source;
}

sub get_source { $_[0]->{'source'} }

=head2 $o->set_zone($zone)

Set the zone in which the object will be displayed.

=cut

sub set_zone {
    my ($self, $zone) = @_;
    $self->{'zone'} = $zone;
}

=head2 $o->set_special_scale($scale)

Use a special scale to draw this object.

=cut

sub set_special_scale {
    my ($self, $scale) = @_;
    $self->{'special_scale'} = $scale;
}

=head2 my $o_scale = $o->get_scale()

Return the associated scale. If it exists, it uses the special scale,
otherwise returns the default scale associated to the zone.

=cut

sub get_scale {
    my ($self) = @_;
    if (defined($self->{'special_scale'})) {
        return $self->{'special_scale'};
    }
    return $self->{'zone'}->get_default_scale();
}

=head2 $o->set_background_color($color)

Use this color as background color.

=cut

sub set_background_color {
    my ($self, $color) = @_;
    $self->{'bg_color'} = get_color($color);
}

=head2 $o->set_foreground_color($color)

Use this color as foreground color.

=cut

sub set_foreground_color {
    my ($self, $color) = @_;
    $self->{'fg_color'} = get_color($color);
}

=head2 my $o_scale = $o->get_background_color()

return the objects background color.

=cut

sub get_background_color {
    my ($self) = @_;

    return ( defined $self->{'bg_color'} )
     ? @{ $self->{'bg_color'} }
     : undef;
}

=head2 my $o_fgc = $o->get_foreground_color()

return the objects foreground color.

=cut

sub get_foreground_color {
    my ($self) = @_;

    return ( defined $self->{'fg_color'} )
     ? @{ $self->{'fg_color'} }
     : undef;
}

1;
