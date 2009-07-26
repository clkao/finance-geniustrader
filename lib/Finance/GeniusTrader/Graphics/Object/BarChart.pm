package Finance::GeniusTrader::Graphics::Object::BarChart;

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

Finance::GeniusTrader::Conf::default("Graphic::BarChart::UpColor",   "green");
Finance::GeniusTrader::Conf::default("Graphic::BarChart::DownColor", "red");
Finance::GeniusTrader::Conf::default("Graphic::BarChart::Width", 6);

=head1 Finance::GeniusTrader::Graphics::Object::BarChart

This graphical object display a serie of bars.

=cut

sub init {
    my ($self) = @_;
    
    # Default values ...
    $self->{'up_color'} = 
		    get_color(Finance::GeniusTrader::Conf::get("Graphic::BarChart::UpColor"));
    $self->{'down_color'} = 
		    get_color(Finance::GeniusTrader::Conf::get("Graphic::BarChart::DownColor"));
    $self->{'width'} = Finance::GeniusTrader::Conf::get("Graphic::BarChart::Width");
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
    for(my $i = $start; $i <= $end; $i++)
    {
	my $data = $self->{'source'}->get($i);
	my $low = $scale->convert_to_y_coordinate($data->[$LOW]);
	my $open = $scale->convert_to_y_coordinate($data->[$OPEN]);
	my $close = $scale->convert_to_y_coordinate($data->[$CLOSE]);
	my $high = $scale->convert_to_y_coordinate($data->[$HIGH]);
	my $x = $scale->convert_to_x_coordinate($i);
	my $color = ($open < $close) ? $self->{'up_color'} :
				       $self->{'down_color'};
	$x += $offset;
	$driver->line($picture,
	    $zone->absolute_coordinate($x + int($width / 2) - 1, $low),
	    $zone->absolute_coordinate($x + int($width / 2) - 1, $high),
	    $color);
	$driver->line($picture,
	    $zone->absolute_coordinate($x, $open),
	    $zone->absolute_coordinate($x + int($width / 2) - 1, $open),
	    $color);
	$driver->line($picture,
	    $zone->absolute_coordinate($x + int($width / 2) - 1, $close),
	    $zone->absolute_coordinate($x + $width - 2, $close),
	    $color);
    }
}

1;
