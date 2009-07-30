package GT::Graphics::Object::Positions;

# Copyright 2007 ras
# $Id: Positions.pm,v 1.9 2009/03/02 06:24:18 ras Exp ras $
# 
# based on a heavily modified Orders.pm Copyright 2005 Samal Chandran
# original version taken from devel archive 12 Feb 2005
# which was developed from Oliver Bossert's Trades.pm
# 
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.
#
# ras hack module features:
# @ marks all portfolio positions, closed or open
# @ an optionally drawn open position price line
#   at the position opening price
#   price lines are not drawn for closed positions
# @ buy-sell arrows with right pointing apex when a position is opened
#   left pointing apex when a position is closed
# @ colors for all graphic symbols are transparent, but based on
#   application defaults "Graphic::Positions::BuyColor"
#   and "Graphic::Positions::SellColor"
#   green for buys (longs)
#   red for sells (shorts)
#
# weaknesses
# * price line plots fail when a position has multiple buys and sells
#   issue is complex because there's no easy way to aggregate the position
#
# * price line should include the price value on the axis
#   -- issues: overwriting axis labeling
#
# * price line needs to be clipped at price levels above the price graph
#   fixed
#
# * marker symbol (triangle) size not easily altered with the expectations
#   that apex point will be correctly positioned on actual transaction date
#


use strict;
use vars qw(@ISA);
@ISA = qw(GT::Graphics::Object);

use GT::Prices;
use GT::Graphics::Object;
use GT::Graphics::Driver;
use GT::Graphics::Tools qw(:color);
use GT::Conf;
use Data::Dumper;

GT::Conf::default("Graphic::Positions::BuyColor", "[0,185,0]");
GT::Conf::default("Graphic::Positions::SellColor", "[185,0,0]");
#GT::Conf::default("Graphic::Positions::Width", 6);
GT::Conf::default("Graphic::Positions::Width", 24);

# seems 6 is needed to fill the last bar give or take a couple
# the rest is actual tick length
# fixme
GT::Conf::default("Graphic::Positions::TickLength", 6 + 5);

#my $odbg = 1;    # debug enabled
my $odbg = 0;    # debug disabled

=head1 GT::Graphics::Object::Positions

This graphical object displays all positions in a portfolio on a graph
if the order date coincides with the graph time span.

the default buy orders color is Graphic::Positions::BuyColor which
defaults to 62 % green intensity if not set in .gt/options

the default sell orders color is Graphic::Positions::SellColor which
defaults to 62 % red intensity if not set in .gt/options

the marker color is always adjusted to be a transparent version
of the color specified (and will likely alter the
transparency attribute if it is already set)

if a 6th argument is supplied via Positions->new method and it is
"true" (in perl not zero or something other than "") then a horizontal
line will be drawn from the opening of the position (or start date)
to the end date. price lines are not drawn for closed positions since
the price points will likely differ. the line color will be based on
the type of position, green for long, red for short.

=head1 SYNOPSIS

my $pf = GT::Portfolio->create_from_file("./my_portfolio);

$all_trades = GT::Graphics::Object::Positions->new($calc, $zone, \
 $pf, $first, $last, "enable priceline");

NB: $calc, $zone, required by GT::Graphics::Object::<object>->new()
which Positions.pm inherits. see Object.pm.

$graphic->add_object($all_trades);

  where $calc will yield the security symbol ($code) being processed
        $portfolio contains the portfolio data
        $first, $last are the dates of interest


=head1 EXAMPLES: script code

    (from ras hack of Samal Chandrans' portgraph.pl)

    my $pf = GT::Portfolio->create_from_file($pfname);
    my $all_trades = GT::Graphics::Object::Positions->new(
     $calc, $zone, $pf, $first, $last, "plotline");
    $graphic->add_object($all_trades);
    
    (from ras hack of backtest.pl)

      my $positions = GT::Graphics::Object::Positions->new(
       $calc, $zone, $analysis->{'portfolio'}, $first, $last, "show priceline");
      $positions->set_special_scale($scale_p);
      $graphic->add_object($positions);

=head1 BUGS, NOTES, LIMITATIONS

no testing with widths other than the default width

i selected width of 24 because it was large enough for my old tired
eyes to see on an otherwise cluttered graph but not so large as to
obliterate the adjacent candle sticks

no testing with non-closed short positions. manage_portfolio doesn't
seem to support them (or am i missing something) so i've been unable
to easily mechanize an test/evaluation portfolio with them.

=cut

sub init {
    my $self = shift;
    $self->{'portfolio'} = shift;
    $self->{'first'} = shift;
    $self->{'last'} = shift;
    $self->{'positionline'} = shift;

    $self->{'bcolor'} = get_color(GT::Conf::get(
     "Graphic::Positions::BuyColor"));
    $self->{'scolor'} = get_color(GT::Conf::get(
     "Graphic::Positions::SellColor"));
    $self->{'width'} = GT::Conf::get("Graphic::Positions::Width");

    $self->{'tick_len'} = GT::Conf::get("Graphic::Positions::TickLength");

    # regardless of the color settings in configuration file
    # the colors used will be about 50 percent transparent
    my $tp_color = [ @{$self->{'bcolor'}} ];
    $tp_color->[3] = 64;
    $self->{'bcolor'} = $tp_color;
    
    $tp_color = [ @{$self->{'scolor'}} ];
    $tp_color->[3] = 64;
    $self->{'scolor'} = $tp_color;

}

sub display {
    my ($self, $driver, $picture) = @_;
    my $zone = $self->{'zone'};
    my $scale = $self->get_scale();
    my $calc = $self->{'source'};
    my $order_date;
    my $height;

    my $graphic_tf = $calc->prices->{'timeframe'};

    # check for open positions
    foreach my $position (@{$self->{'portfolio'}->{'open_positions'}}) {

      next unless defined $position;

      next unless $position->{'code'} eq $calc->{'code'};

      print STDERR "open position: sym '$position->{'code'}',"
      . " '$calc->{'code'}'\n"
       if $odbg != 0;

      if ( $position->{'timeframe'} < $graphic_tf ) {

        print STDERR "graphic timeframe ", $graphic_tf,
         ", converting all dates\n"
         if $odbg != 0;

        $position->{'open_date'} = GT::DateTime::convert_date(
         $position->{'open_date'},
         $position->{'timeframe'},
         $graphic_tf
        );
        $position->{'timeframe'} = $graphic_tf;

        foreach my $dpos ($position->list_detailed_orders) {
          $dpos->{'date'} = GT::DateTime::convert_date(
           $dpos->{'date'},
           $dpos->{'timeframe'},
           $graphic_tf
          );
          $dpos->{'timeframe'} = $graphic_tf;
        }

      }

      if ( $self->{'positionline'} ) {

        # plot $width length line for this date
        plot_position_line( $self, $driver, $picture, $zone,
                            $scale, $calc, $position );
      }

      # don't plot if point outside (time span) of plot
#      next if ( $order_date < $self->{'first'} );

      plot_position( $self, $driver, $picture, $zone,
                     $scale, $calc, $height, $position );
    }

    # check for fully closed positions
    foreach my $position (@{$self->{'portfolio'}->{'history'}}) {

      next unless defined $position;

      next unless $position->{'code'} eq $calc->{'code'};

      print STDERR "closed postion: sym '$position->{'code'}',"
       . " '$calc->{'code'}'\n"
       if $odbg != 0;

      if ( $position->{'timeframe'} < $graphic_tf ) {

        print STDERR "graphic timeframe ", $graphic_tf,
        ", converting all dates\n" if $odbg != 0;

        $position->{'open_date'} = GT::DateTime::convert_date(
         $position->{'open_date'},
         $position->{'timeframe'},
         $graphic_tf
        );
        $position->{'timeframe'} = $graphic_tf;

        foreach my $dpos ($position->list_detailed_orders) {
          $dpos->{'date'} = GT::DateTime::convert_date(
           $dpos->{'date'},
           $dpos->{'timeframe'},
           $graphic_tf
          );
          $dpos->{'timeframe'} = $graphic_tf;
        }
      }

#      $order_date = $calc->prices->date($position->{'open_date'});

#      # don't plot if point outside (time span) of plot
#      next if ( $order_date < $self->{'first'}
#             || $order_date > $self->{'last'} );

      print STDERR "closed position\n" if $odbg != 0;

      plot_position( $self, $driver, $picture, $zone,
                     $scale, $calc, $height, $position );
    }
}


sub plot_position_line {
  my ( $self, $driver, $picture, $zone, $scale, $calc, $position ) = @_;
  #my $width = $self->{'width'};
  my $tick_len = $self->{'tick_len'};

  foreach my $order ($position->list_detailed_orders) {
    my $x = $scale->convert_to_x_coordinate($calc->prices->date(
     $calc->prices->find_nearest_date($order->submission_date)));

    my $xend = $scale->convert_to_x_coordinate($self->{'last'});
    my $y = $scale->convert_to_y_coordinate($order->price);

    # clipping at zone top boundary
    next if $y > $zone->height+1;
    # clipping at zone bottom boundary
    next if $y < 0;

    # clip at left boundary
    $x = $scale->convert_to_x_coordinate( $self->{'first'} )
     if $x < $scale->convert_to_x_coordinate( $self->{'first'} );

    if ( $order->is_buy_order ) {
      #print STDERR "buy -- ";
      if ( $position->is_long ) {  # open long position buy
        $driver->line($picture, 
          $zone->absolute_coordinate($x + 1, $y),
#          $zone->absolute_coordinate($xend + 10, $y),
          $zone->absolute_coordinate($xend + $tick_len, $y),
          $self->{'bcolor'}
        );
      } else {                       # close short position buy
        # untested code
        #
        # this should really set the end-point
        # for a quantity matched prior short sale -- gets complex when myriad
        # multiple combinations are considered
        #
        #$driver->line($picture,
        #  $zone->absolute_coordinate($x + 3, $y),
        #  $zone->absolute_coordinate($xend,  $y),
        #  $self->{'scolor'});
      }
    } else {
      #print STDERR "sell -- ";
      if ( $position->is_long ) {  # close long position sell draw no line\
        #
        # this should really set the end-point
        # for a quantity matched prior long buy -- gets complex when myriad
        # multiple combinations are considered
        #
        #$driver->line($picture,
        #  $zone->absolute_coordinate($x + 3, $y),
        #  $zone->absolute_coordinate($xend,  $y),
        #  $self->{'scolor'});
      } else {                       # open short position sell
        # untested code
        $driver->line($picture,
          $zone->absolute_coordinate($x + 1, $y),
#          $zone->absolute_coordinate($xend + 10, $y),
          $zone->absolute_coordinate($xend + $tick_len, $y),
          $self->{'bcolor'}
        );
      }
    }
  }
}


sub plot_position {
  my ( $self, $driver, $picture, $zone, $scale, $calc, $height, $position )
   = @_;

  $height = int( $self->{'width'} / 2 );
  $height = 2 if $height < 2;

  foreach my $order ($position->list_detailed_orders) {
    my $x = $scale->convert_to_x_coordinate($calc->prices->date(
     $calc->prices->find_nearest_date($order->submission_date)));
    my $y = $scale->convert_to_y_coordinate($order->price);

    # clip at left boundary
    next if $x < $scale->convert_to_x_coordinate( $self->{'first'} );
    # right of zone clipping
    next if $x > $scale->convert_to_x_coordinate( $self->{'last'} );
    
    # clipping at zone top boundary
    next if $y > $zone->height+1;
    # clipping at zone bottom boundary
    next if $y < 0;
    
    if ( $order->is_buy_order ) {
      #print STDERR "buy -- ";
      if ( $position->is_long ) {  # open long position buy
        #print STDERR "  open long green|>\n";
        my $op_pos_x_apex = $x + 1;
        my $op_pos_x_base = $op_pos_x_apex - $height;
        my @open_pos_arrow = (
             [ $zone->absolute_coordinate($op_pos_x_apex, $y        ) ],
             [ $zone->absolute_coordinate($op_pos_x_base, $y+$height) ],
             [ $zone->absolute_coordinate($op_pos_x_base, $y-$height) ]
           );
        $driver->filled_polygon($picture, $self->{'bcolor'}, @open_pos_arrow);
      } else {                       # close short position buy
        #print STDERR "  <|green short close\n";
        my $cl_pos_x_apex = $x + 3;
        my $cl_pos_x_base = $cl_pos_x_apex + $height;
        my @close_pos_arrow = (
             [ $zone->absolute_coordinate($cl_pos_x_apex, $y        ) ],
             [ $zone->absolute_coordinate($cl_pos_x_base, $y+$height) ],
             [ $zone->absolute_coordinate($cl_pos_x_base, $y-$height) ]
           );   
        $driver->filled_polygon($picture, $self->{'bcolor'}, @close_pos_arrow);
      }
    } else {
      #print STDERR "sell -- ";
      if ( $position->is_long ) {  # close long position sell
        #print STDERR "  <|red long close\n";
        my $cl_pos_x_apex = $x + 3;
        my $cl_pos_x_base = $cl_pos_x_apex + $height;
        my @close_pos_arrow = (
             [ $zone->absolute_coordinate($cl_pos_x_apex, $y        ) ],
             [ $zone->absolute_coordinate($cl_pos_x_base, $y+$height) ],
             [ $zone->absolute_coordinate($cl_pos_x_base, $y-$height) ]
           );
        $driver->filled_polygon($picture, $self->{'scolor'}, @close_pos_arrow);
      } else {                       # open short position sell
        #print STDERR "  open short red|>\n";
        my $op_pos_x_apex = $x + 1;
        my $op_pos_x_base = $op_pos_x_apex - $height;
        my @open_pos_arrow = (
             [ $zone->absolute_coordinate($op_pos_x_apex, $y        ) ],
             [ $zone->absolute_coordinate($op_pos_x_base, $y+$height) ],
             [ $zone->absolute_coordinate($op_pos_x_base, $y-$height) ]
           );
        $driver->filled_polygon($picture, $self->{'scolor'}, @open_pos_arrow);
      }
    }
  }
}

1;
