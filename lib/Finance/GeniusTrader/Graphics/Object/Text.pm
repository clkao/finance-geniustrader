package Finance::GeniusTrader::Graphics::Object::Text;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
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

Finance::GeniusTrader::Conf::default("Graphic::Text::Color", "black");

=head1 Finance::GeniusTrader::Graphics::Object::Text

This graphical object displays a block of text.

=cut

sub init {
    my ($self, $x, $y, $halign, $valign) = @_;
    
    $halign = "left" if (! defined($halign));
    $valign = "top" if (! defined($valign));
    
    # Default values ...
    $self->{'fg_color'} = get_color(Finance::GeniusTrader::Conf::get("Graphic::Text::Color"));
    $self->{'x_pc'} = $x / 100;
    $self->{'y_pc'} = $y / 100;
    $self->set_horizontal_align($halign);
    $self->set_vertical_align($valign);
    $self->{'font_size'} = $FONT_SIZE_SMALL;
    $self->{'font_face'} = $FONT_FIXED;
}

=head2 $o->set_horizontal_align($value)

=head2 $o->set_vertical_align($value)

=head2 $o->set_x_position($value_in_pc)

=head2 $o->set_y_position($value_in_pc)

=head2 $o->set_font_size($fontsize)

=head2 $o->set_font_face($font_face)

=cut
sub set_horizontal_align {
    my ($self, $align) = @_;
    if ($align =~ /middle|center/i) {
	$self->{'halign'} = $ALIGN_CENTER;
    } elsif ($align =~ /left/i) {
	$self->{'halign'} = $ALIGN_LEFT;
    } elsif ($align =~ /right/i) {
	$self->{'halign'} = $ALIGN_RIGHT;
    } else {
	die "Bad alignment: $align !\n";
    }
}
sub set_vertical_align {
    my ($self, $align) = @_;
    if ($align =~ /middle|center/i) {
	$self->{'valign'} = $ALIGN_CENTER;
    } elsif ($align =~ /top/i) {
	$self->{'valign'} = $ALIGN_TOP;
    } elsif ($align =~ /bottom/i) {
	$self->{'valign'} = $ALIGN_BOTTOM;
    } else {
	die "Bad alignment: $align !\n";
    }
}
sub set_x_position { $_[0]->{'x_pc'} = $_[1] / 100 }
sub set_y_position { $_[0]->{'y_pc'} = $_[1] / 100 }
sub set_font_size { $_[0]->{'font_size'} = $_[1] }
sub set_font_face { $_[0]->{'font_face'} = $_[1] }

sub display {
    my ($self, $driver, $picture) = @_;
    my $zone = $self->{'zone'};
    
    $driver->string($picture, $self->{'font_face'}, $self->{'font_size'},
	$self->{'fg_color'}, 
	$zone->absolute_coordinate($self->{'x_pc'} * $zone->width,
				   $self->{'y_pc'} * $zone->height),
	$self->{'source'}, $self->{'halign'}, $self->{'valign'},
	$ORIENTATION_RIGHT);
}

1;
