package GT::Graphics::Object::BuySellArrows;

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

GT::Conf::default("Graphic::BuySellArrows::BuyColor", "green");
GT::Conf::default("Graphic::BuySellArrows::SellColor", "red");
GT::Conf::default("Graphic::BuySellArrows::Distance", 8);
GT::Conf::default("Graphic::Candle::Height", 3);

=head1 GT::Graphics::Object::BuySellArrows

This graphical object display buy and sell arrows.

=cut

sub init {
    my ($self, $prices_ds) = @_;
    
    # Default values ...
    $self->{'buy_color'} = get_color(GT::Conf::get("Graphic::BuySellArrows::BuyColor"));
    $self->{'sell_color'} = get_color(GT::Conf::get("Graphic::BuySellArrows::SellColor"));
    $self->{'distance'} = GT::Conf::get("Graphic::BuySellArrows::Distance");
    $self->{'height'} = GT::Conf::get("Graphic::Candle::Height");
    $self->{'prices_ds'} = $prices_ds;
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
		$scale->convert_to_x_coordinate($start);
    my $y_zero = $scale->convert_to_y_coordinate(0);
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
	    my @points = (
		[$zone->absolute_coordinate($x + int($space / 2) - 1, $low - $self->{'distance'})],
		[$zone->absolute_coordinate($x, $low - $self->{'distance'} - $self->{'height'})],
		[$zone->absolute_coordinate($x + $space - 2, $low - $self->{'distance'} - $self->{'height'})]
	    );
	    $driver->filled_polygon($picture, $self->{'buy_color'}, @points);
	}
	
	# Draw a Down and Red Arrow if value = -1
	if ($value eq -1) {
	    my @points = (
                [$zone->absolute_coordinate($x + int($space / 2) - 1, $high + $self->{'distance'})],
                [$zone->absolute_coordinate($x, $high + $self->{'distance'} + $self->{'height'})],
                [$zone->absolute_coordinate($x + $space - 2, $high + $self->{'distance'} + $self->{'height'})]
            );
            $driver->filled_polygon($picture, $self->{'sell_color'}, @points);
	}
    }
}

1;
