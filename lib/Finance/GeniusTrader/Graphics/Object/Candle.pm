package GT::Graphics::Object::Candle;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# ras hack based on trunk version dated 30may05
# $Id$

use strict;
use vars qw(@ISA);
@ISA = qw(GT::Graphics::Object);

use GT::Prices;
use GT::Graphics::Object;
use GT::Graphics::Driver;
use GT::Graphics::Tools qw(:color);
use GT::Conf;

GT::Conf::default("Graphic::Candle::UpColor", "green");
GT::Conf::default("Graphic::Candle::DownColor", "red");
GT::Conf::default("Graphic::Candle::Width", 6);

=head1 GT::Graphics::Object::Candle

This graphical object display a series of candlesticks.

=cut

sub init {
    my ($self) = @_;
    
    # Default values ...
    $self->{'up_body_color'} = 
			get_color(GT::Conf::get("Graphic::Candle::UpColor"));
    $self->{'up_body_border_color'} = 
			get_color(GT::Conf::get_first(
			    "Graphic::Candle::UpBorderColor",
			    "Graphic::Candle::BorderColor",
			    "Graphic::ForegroundColor"
			));
    $self->{'up_shadows_color'} = 
			get_color(GT::Conf::get_first(
			    "Graphic::Candle::UpShadowColor",
			    "Graphic::Candle::ShadowColor",
			    "Graphic::Candle::UpBorderColor",
			    "Graphic::Candle::BorderColor",
			    "Graphic::ForegroundColor"
			));
    
    $self->{'down_body_color'} =
			get_color(GT::Conf::get("Graphic::Candle::DownColor"));
    $self->{'down_body_border_color'} =
			get_color(GT::Conf::get_first(
			    "Graphic::Candle::DownBorderColor",
			    "Graphic::Candle::BorderColor",
			    "Graphic::ForegroundColor"
			));
    $self->{'down_shadows_color'} =
			get_color(GT::Conf::get_first(
			    "Graphic::Candle::DowbShadowColor",
			    "Graphic::Candle::ShadowColor",
			    "Graphic::Candle::DownBorderColor",
			    "Graphic::Candle::BorderColor",
			    "Graphic::ForegroundColor"
			));
    
    $self->{'width'} = GT::Conf::get("Graphic::Candle::Width");
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my $width = $self->{'width'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
                $scale->convert_to_x_coordinate($start);
    my $offset = int($space/2) - int($width/2);
    $offset = 0 if $offset < 1;

    # only $y_min and $y_max are significant
    my ($x_min, $y_min) = $scale->get_value_from_coordinate($start, 0);
    my ($x_max, $y_max) = $scale->get_value_from_coordinate($end, $zone->height-1);

    # these are coordinate values of $y_min and $y_max
    my $yc_min = $scale->convert_to_y_coordinate($y_min);
    my $yc_max = $scale->convert_to_y_coordinate($y_max);

	for(my $i = $start; $i <= $end; $i++)
    {
	my $data = $self->{'source'}->get($i);
	my $low = $scale->convert_to_y_coordinate($data->[$LOW]);
	my $open = $scale->convert_to_y_coordinate($data->[$OPEN]);
	my $close = $scale->convert_to_y_coordinate($data->[$CLOSE]);
	my $high = $scale->convert_to_y_coordinate($data->[$HIGH]);
	my $x = $scale->convert_to_x_coordinate($i);
	$x += $offset;

	# clip $y at top of zone
        $low   = $yc_max if ( $low   > $yc_max );
        $open  = $yc_max if ( $open  > $yc_max );
        $close = $yc_max if ( $close > $yc_max );
        $high  = $yc_max if ( $high  > $yc_max );
	# clip $y at bottom of zone
        $low   = $yc_min if ( $low   < $yc_min );
        $open  = $yc_min if ( $open  < $yc_min );
        $close = $yc_min if ( $close < $yc_min );
        $high  = $yc_min if ( $high  < $yc_min );

    if ($data->[$OPEN] < $data->[$CLOSE]) {
	
	    $driver->filled_rectangle($picture, 
		$zone->absolute_coordinate($x + 1, $open + 1),
		$zone->absolute_coordinate($x + $width - 2 - 1, $close - 1),
		$self->{'up_body_color'});

	    $driver->rectangle($picture,
		$zone->absolute_coordinate($x, $open),
	    	$zone->absolute_coordinate($x + $width - 2, $close),
		$self->{'up_body_border_color'});
		    
	    $driver->line($picture,
		$zone->absolute_coordinate($x + int($width / 2) - 1, $close + 1),
		$zone->absolute_coordinate($x + int($width / 2) - 1, $high), $self->{'up_shadows_color'});
		
	    $driver->line($picture,
		$zone->absolute_coordinate($x + int($width / 2) - 1, $low),
		$zone->absolute_coordinate($x + int($width / 2) - 1, $open - 1), $self->{'up_shadows_color'});

	} else {
	    
	    $driver->filled_rectangle($picture,
		$zone->absolute_coordinate($x + 1, $close + 1),
		$zone->absolute_coordinate($x + $width - 2 - 1, $open - 1), $self->{'down_body_color'});

	    $driver->rectangle($picture, 
		$zone->absolute_coordinate($x, $close),
		$zone->absolute_coordinate($x + $width - 2, $open), $self->{'down_body_border_color'});

	    $driver->line($picture,
		$zone->absolute_coordinate($x + int($width / 2) - 1, $open + 1),
		$zone->absolute_coordinate($x + int($width / 2) - 1, $high), $self->{'down_shadows_color'});
		
	    $driver->line($picture,
		$zone->absolute_coordinate($x + int($width / 2) - 1, $low),
		$zone->absolute_coordinate($x + int($width / 2) - 1, $close - 1), $self->{'down_shadows_color'});
	}
    }
}

1;
