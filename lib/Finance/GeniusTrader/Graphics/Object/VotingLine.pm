package Finance::GeniusTrader::Graphics::Object::VotingLine;

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
use Finance::GeniusTrader::Tools qw(:math);
use Finance::GeniusTrader::Conf;

Finance::GeniusTrader::Conf::default("Graphic::VotingLine::BuyColor", "green");
Finance::GeniusTrader::Conf::default("Graphic::VotingLine::SellColor", "red");
Finance::GeniusTrader::Conf::default("Graphic::VotingLine::Height", 4);
Finance::GeniusTrader::Conf::default("Graphic::VotingLine::Width", 4);

=head1 Finance::GeniusTrader::Graphics::Object::VotingLine

This graphical object display buy and sell arrows.

The Voting Line contains the results of a System Manager, which is an entity
interacting between a Portfolio Manager, a Trading System, an Order Factory,
Trade Filters and Close Strategies.

=cut

sub init {
    my ($self, $y) = @_;
    
    # Default values ...
    $self->{'buy_color'} = get_color(
	    Finance::GeniusTrader::Conf::get("Graphic::VotingLine::BuyColor")
	);
    $self->{'sell_color'} = get_color(
	    Finance::GeniusTrader::Conf::get("Graphic::VotingLine::SellColor")
	);
    $self->{'height'} = Finance::GeniusTrader::Conf::get("Graphic::VotingLine::Height");
    $self->{'width'} = Finance::GeniusTrader::Conf::get("Graphic::VotingLine::Width");
    $self->{'y'} = 0;
    $self->{'y'} = $y if (defined($y));
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
		$scale->convert_to_x_coordinate($start);
    my $width = max($space - 2, $self->{'width'});
    my $y = $self->{'y'};
    my ($position, $last_position) = (0, 0);
    
    for(my $i = $start; $i <= $end; $i++)
    {
	my $x = $scale->convert_to_x_coordinate($i);
	my $value = $self->{'source'}->get($i);
	
	# Draw an Up and Green Arrow if value = 1
	if ($value == 1) {
	    my @points = (
		[$zone->absolute_coordinate($x + int($width/2), 
					    $y + $self->{'height'})],
		[$zone->absolute_coordinate($x, $y)],
		[$zone->absolute_coordinate($x + $width, $y)]
	    );
	    $driver->filled_polygon($picture, $self->{'buy_color'}, @points);
	    $position = 1;
	}
	
	# Draw a Down and Red Arrow if value = -1
	if ($value == -1) {
	    my @points = (
                [$zone->absolute_coordinate($x + int($width / 2), $y)],
                [$zone->absolute_coordinate($x, $y + $self->{'height'})],
                [$zone->absolute_coordinate($x + $width,
					    $y + $self->{'height'})]
            );
            $driver->filled_polygon($picture, $self->{'sell_color'}, @points);
	    $position = -1;
	}
	
	next if (! $position);
	
	# The line is made of two parts, the part before, and the part
	# after, each can be drawed on the top or on the bottom
	my ($left_part, $right_part, $left_top, $right_top) = (0, 0);
	
	$left_top = ($last_position == 1); # Drawed on top if system was buying
	$right_top = ($position == 1); # Drawed on top if system is buying

	$left_part = ($position == $last_position); # If position changed only
	$right_part = 1; # Always
	
	$driver->line($picture,
	    $zone->absolute_coordinate($x + int($width / 2) - 1,
				       $y + $self->{'height'} * $left_top),
	    $zone->absolute_coordinate($x, $y + $self->{'height'} * $left_top),
	    $left_top ? $self->{'buy_color'} : $self->{'sell_color'})
		if ($left_part);

	$driver->line($picture,
	    $zone->absolute_coordinate($x + int($width / 2),
				       $y + $self->{'height'} * $right_top),
	    $zone->absolute_coordinate($x + $space - 1,
				       $y + $self->{'height'} * $right_top),
	    $right_top ? $self->{'buy_color'} : $self->{'sell_color'})
		if ($right_part);
		
	$last_position = $position;
    }
}

1;
