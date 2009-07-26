package GT::Graphics::Object::BuySellArrows;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Copyright 2008 Robert A. Schmied
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# ras hack based on version dated 24apr05 2865 bytes
# $Id$

use strict;
use vars qw(@ISA);
@ISA = qw(GT::Graphics::Object);

use GT::Prices;
use GT::Graphics::Object;
use GT::Graphics::Driver;
use GT::Graphics::Tools qw(:color);
use GT::Conf;

GT::Conf::default("Graphic::BuySellArrows::BuyColor", "green");
GT::Conf::default("Graphic::BuySellArrows::SellColor", "red");
GT::Conf::default("Graphic::BuySellArrows::Distance", 8);
GT::Conf::default("Graphic::Candle::Height", 3);

GT::Conf::default("Graphic::BuySellArrows::SizeFactor", 1);
# SizeFactor can be used to adjust the default size in both height and width
# without it the width cannot be altered
#
# i recommend altering the size via the SizeFactor and leave Graphic::Candle::Height at 3
#
# i considered changing Graphic::Candle::Height to the more logical Graphic::BuySellArrows::Height
# but didn't know if there was a ulterior motive for this name or not so i left it alone
#

# we should also transparent these colors as well -- ah well you can do
# that in your gt config options file:
#   Graphic::BuySellArrows::BuyColor    "[0,135,0,64]"  # partly transparent dark green
#   Graphic::BuySellArrows::SellColor   "[150,0,0,64]"  # partly transparent dark red
#

=head1 GT::Graphics::Object::BuySellArrows

This graphical object display buy and sell arrows.

=head2 Description and Usage

the object doesn't accept arguments when created, however it reads gt configure file
for and sets these values (default values are indicated):

  Graphic::BuySellArrows::BuyColor      "green"
  Graphic::BuySellArrows::SellColor     "red"
  Graphic::BuySellArrows::Distance      8
  Graphic::Candle::Height               3
  Graphic::BuySellArrows::SizeFactor    1

note: the default SizeFactor of 1 should make this modified version work
      identically to the prior version

personally, i find a Distance of about 24 and a SizeFactor of 3 to 6 makes the arrow
plot better. in addition i prefer to darken the colors and make the partly transparent

 Graphic::BuySellArrows::BuyColor       "[0,135,0,64]"  # very dark green
 Graphic::BuySellArrows::SellColor      "[150,0,0,64]"  # dark red


=head2 used in graphic.pl graphic configuration file as shown below:

=head2 plotting on the primary price plot

 --add=BuySellArrows(Systems::Generic \
  { S::Generic::CrossOverUp   {I::MACD/1 26 52 20} {I::MACD/2 26 52 20} } \
  { S::Generic::CrossOverDown {I::MACD/1 26 52 20} {I::MACD/2 26 52 20} } \
  )

=head2 plotting arrows on a secondary zone

--add=New-Zone(5)

--add=New-Zone(100)
--add=Curve(I:MACD/1 26 52 20, [120, 40, 0])
--add=Curve(I:MACD/2 26 52 20, red)
--add=Text("macd: 26 52 20",  2, 95, left, center, small, [120, 40, 0], arial)
--add=Set-Scale(auto)

--add=BuySellArrows(Systems::Generic \
 { S::Generic::CrossOverUp   {I::MACD/1 26 52 20} {I::MACD/2 26 52 20} } \
 { S::Generic::CrossOverDown {I::MACD/1 26 52 20} {I::MACD/2 26 52 20} } \
 )
--add=Set-Special-Scale(auto,"log")


=cut

sub init {
    my ($self, $prices_ds) = @_;
    
    # Default values ...
    $self->{'buy_color'} = get_color(GT::Conf::get("Graphic::BuySellArrows::BuyColor"));
    $self->{'sell_color'} = get_color(GT::Conf::get("Graphic::BuySellArrows::SellColor"));
    $self->{'distance'} = GT::Conf::get("Graphic::BuySellArrows::Distance");
    $self->{'height'} = GT::Conf::get("Graphic::Candle::Height");
    $self->{'sizefactor'} = GT::Conf::get("Graphic::BuySellArrows::SizeFactor");
    $self->{'prices_ds'} = $prices_ds;
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
		$scale->convert_to_x_coordinate($start);

    my $xoff = int($space * $self->{'sizefactor'} / 2);
    my $arrowht = int($self->{'height'} * $self->{'sizefactor'});

    for(my $i = $start; $i <= $end; $i++)
    {
	my $prices = $self->{'prices_ds'}->get($i);
	my $low = $scale->convert_to_y_coordinate($prices->[$LOW]);
	my $high = $scale->convert_to_y_coordinate($prices->[$HIGH]);
	my $x = $scale->convert_to_x_coordinate($i);

	# Get the datasource value :
	#  1 => buy signal
	#  0 => no signal
	# -1 => sell signal
	my $value = $self->{'source'}->get($i);
	
	# Draw an Up and Green Arrow if value = 1
	if ($value eq 1) {
            my $yb = $low - $self->{'distance'} - $arrowht;
            my $xa = $x + int($space / 2) - 1;
            ( $xa, my $ya ) = ( $xa, $low - $self->{'distance'} );
            my ( $x2, $y2 ) = ( $xa - int($xoff / 2),  $yb );
            my ( $x3, $y3 ) = ( $xa + int($xoff / 2),  $yb );
	    my @points = (
                [$zone->absolute_coordinate( $xa, $ya )],
                [$zone->absolute_coordinate( $x2, $y2 )],
                [$zone->absolute_coordinate( $x3, $y3 )]
	    );
	    $driver->filled_polygon($picture, $self->{'buy_color'}, @points);
	}
	
	# Draw a Down and Red Arrow if value = -1
	if ($value eq -1) {
            my $yb = $high + $self->{'distance'} + $arrowht;
            my $xa = $x + int($space / 2) - 1;
            ( $xa, my $ya ) = ( $xa, $high + $self->{'distance'} );
            my ( $x2, $y2 ) = ( $xa - int($xoff / 2),  $yb );
            my ( $x3, $y3 ) = ( $xa + int($xoff / 2),  $yb );
	    my @points = (
                [$zone->absolute_coordinate( $xa, $ya )],
                [$zone->absolute_coordinate( $x2, $y2 )],
                [$zone->absolute_coordinate( $x3, $y3 )]
            );
            $driver->filled_polygon($picture, $self->{'sell_color'}, @points);
	}
    }
}

1;
