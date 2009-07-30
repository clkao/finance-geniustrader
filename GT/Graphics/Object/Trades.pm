package GT::Graphics::Object::Trades;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id: Trades.pm,v 1.2 2009/07/30 00:35:31 ras Exp ras $

use strict;
use vars qw(@ISA);
@ISA = qw(GT::Graphics::Object);

use GT::Prices;
use GT::Graphics::Object;
use GT::Graphics::Driver;
use GT::Graphics::Tools qw(:color);
use GT::Conf;

GT::Conf::default("Graphic::Trades::LosingLine", "[255,0,255]");
GT::Conf::default("Graphic::Trades::WinningLine", "[255,170,0]");
GT::Conf::default("Graphic::Trades::BuyArrow", "[185,0,0]");
GT::Conf::default("Graphic::Trades::SellArrow", "[0,185,0]");
GT::Conf::default("Graphic::Trades::Width", 6);

=head1 GT::Graphics::Object::Trades

This graphical object displays trades as markers on a plot.

has opaque colors for lines and arrows

=cut

sub init {
    my $self = shift;
    $self->{'portfolio'} = shift;
    $self->{'first'} = shift;
    $self->{'last'} = shift;

    $self->{'ll_color'} = get_color(
     GT::Conf::get("Graphic::Trades::LosingLine"));
    $self->{'wl_color'} = get_color(
     GT::Conf::get("Graphic::Trades::WinningLine"));
    $self->{'ba_color'} = get_color(
     GT::Conf::get("Graphic::Trades::BuyArrow"));
    $self->{'sa_color'} = get_color(
     GT::Conf::get("Graphic::Trades::SellArrow"));
    $self->{'width'} = GT::Conf::get("Graphic::Trades::Width");
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $zone = $self->{'zone'};
    my $scale = $self->get_scale();
    my $calc = $self->{'source'};

    foreach my $position (@{$self->{'portfolio'}->{'history'}}) {
      next unless defined $position;

      my $start = $calc->prices->date($position->{'open_date'});

      next if $start > $self->{'last'};
      next if $start < $self->{'first'};

      my $end = $calc->prices->date($position->{'close_date'});
      my $open = $position->open_price();
      my $close = $position->{'details'}->[1]->{'price'};
      $end = $self->{'last'} if ($end > $self->{'last'});

      # Difference 
      my $linecolor = $self->{'wl_color'};
      if      ( $position->is_long && ($open > $close) ) {
        $linecolor = $self->{'ll_color'};
      } elsif ( $position->is_short && ($open < $close) ) {
        $linecolor = $self->{'ll_color'};
      }

      $driver->line($picture,
                    $zone->absolute_coordinate($scale->convert_to_x_coordinate($start), 
                                               $scale->convert_to_y_coordinate($open)),
                    $zone->absolute_coordinate($scale->convert_to_x_coordinate($end), 
                                               $scale->convert_to_y_coordinate($open)),
                    $linecolor
                   );

      $driver->line($picture,
                    $zone->absolute_coordinate($scale->convert_to_x_coordinate($end), 
                                               $scale->convert_to_y_coordinate($open)),
                    $zone->absolute_coordinate($scale->convert_to_x_coordinate($end), 
                                               $scale->convert_to_y_coordinate($close)),
                    $linecolor
                   );

      # Draw the arrows
      my $height = int( $self->{'width'} / 2 );
      $height = 2 if ($height < 2);
      my $buy_x = $scale->convert_to_x_coordinate($start);
      my $buy_y = $scale->convert_to_y_coordinate($open) - $height;
      my $sell_x = $scale->convert_to_x_coordinate($end);
      my $sell_y = $scale->convert_to_y_coordinate($close) + $height;
      if ( $position->is_long ) {
        $sell_x = $scale->convert_to_x_coordinate($start);
        $sell_y = $scale->convert_to_y_coordinate($open);
        $buy_x = $scale->convert_to_x_coordinate($end);
        $buy_y = $scale->convert_to_y_coordinate($close);
      }

      my @points = ( 
                    [ $zone->absolute_coordinate($buy_x, $buy_y) ],
                    [ $zone->absolute_coordinate($buy_x+$height,
                                                 $buy_y+$height) ],
                    [ $zone->absolute_coordinate($buy_x-$height,
                                                 $buy_y+$height) ]
                   );
      $driver->filled_polygon($picture, $self->{'ba_color'}, @points);

      @points = ( 
                 [ $zone->absolute_coordinate($sell_x,
                                              $sell_y) ],
                 [ $zone->absolute_coordinate($sell_x+$height,
                                              $sell_y-$height) ],
                 [ $zone->absolute_coordinate($sell_x-$height,
                                              $sell_y-$height) ]
                );
      $driver->filled_polygon($picture, $self->{'sa_color'}, @points);

    }
}

1;
