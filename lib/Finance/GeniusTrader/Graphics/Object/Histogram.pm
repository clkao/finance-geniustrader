package GT::Graphics::Object::Histogram;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# ras hack -- fixes clipping at zone boundaries
#          -- alternate clipping marker color scheme
# $Id$

use strict;
use vars qw(@ISA);
@ISA = qw(GT::Graphics::Object);

use GT::Prices;
use GT::Graphics::Object;
use GT::Graphics::Driver;
use GT::Graphics::Tools qw(:color);
use GT::Conf;
use GT::Graphics::DataSource::GenericIndicatorResults;

GT::Conf::default("Graphic::Histogram::Color", "yellow");
GT::Conf::default("Graphic::Histogram::ClipColor", "blue");

=head1 GT::Graphics::Object::Histogram

This graphic object displays a histogram.

used in graphic.pl it takes two arguments, an indicator and a color.
it plots vertical bars (histogram) from zone zero to data value.

the histogram default color is "yellow", but can be changed
via configuration option "Graphic::Histogram::Color" and by the
color parameter on the graphic option statement. in addition the
color can be controlled by an indicator as well (see examples).

bars will be clipped at upper and lower zone boundries. clipped bars
will display a small arrow at the clipped end.
there are two hardcoded variations that set the
color of this marker. the old way requires you to edit the file and
set the hash variable $self->{'inverse'} in the sub init method to any value.

    $self->{'inverse'} = 'enable';

in this mode the clip marker color will be the inverse of the
current color. benefits include good contrast with respect to the
histogram especially when an indicator is controlling the color.

currently the clip marker color will be either the default value
"blue" or the value set by your configuration option parameter
"Graphic::Histogram::ClipColor"


=head1 examples

 typical in a graphic config file
   --add=Histogram(I:MACD/3 26 52 20, brown)
   --add=Histogram(I:MACD)
   --add=Histogram(I:VOSC 21, [127,127,127])
   --add=Histogram(I:ADL, "dark blue")

 using indicator to set historgram color: (in options file only)
   Graphic::Histogram::Color Indicators::Generic::If \
    {Signals:Generic:Below {I:Prices OPEN} {I:Prices CLOSE}} green red

=cut

sub init {
    my ($self, $calc) = @_;

    # Default values ...
    $self->{'fg_color'} = GT::Conf::get("Graphic::Histogram::Color");

    $self->{'color_ds'} = undef;

    $self->{'clip_color'} = get_color(
     GT::Conf::get("Graphic::Histogram::ClipColor"));
    
    if (defined($calc)) {
        $self->{'calc'} = $calc;
    }

    if (defined($calc) && $self->{'fg_color'} =~ /^\s*(Indicators|I:)/) {
        $self->{'color_ds'} =
         GT::Graphics::DataSource::GenericIndicatorResults->new(
         $calc, $self->{'fg_color'});
    } else {
        $self->{'fg_color'} = get_color($self->{'fg_color'});
    }

    # set this (to anything) if you prefer the old foreground color inversion
    $self->{'inverse'} = '';
}

=head2 $hist->set_color_datasource($ds)

Use the indicated datasource to retrieve the color of the bar.

=cut
sub set_color_datasource {
    my ($self, $color_ds) = @_;
    $self->{'color_ds'} = $color_ds;
}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my $color = $self->{'fg_color'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
                $scale->convert_to_x_coordinate($start);
    $space = 2 if ($space < 2);
    
    my $yc_zero = $scale->convert_to_y_coordinate(0);

    # only $y_min and $y_max are significant
    my ($x_min, $y_min) = $scale->get_value_from_coordinate($start, 0);
    my ($x_max, $y_max) =
     $scale->get_value_from_coordinate($end, $zone->height-1);

    # these are coordinate values of $y_min and $y_max
    my $yc_min = $scale->convert_to_y_coordinate($y_min);
    my $yc_max = $scale->convert_to_y_coordinate($y_max);

    # clip at zone boundary
    if ( $yc_zero < $yc_min ) {
      $yc_zero = $yc_min;
    } elsif ( $yc_zero > $yc_max ) {
      $yc_zero = $yc_max;
    }
    # mark clip at zone top

    my $tooshort = 0;  # 1 for top clip, -1 for bottom clip
    for(my $i = $start; $i <= $end; $i++)
    {

        next if (! $self->{'source'}->is_available($i));
        my @data = $self->{'source'}->get($i);
        my $y = $scale->convert_to_y_coordinate($data[0]);
        my $x = $scale->convert_to_x_coordinate($i);

        if ($self->{'fg_color'} =~ /^\s*(Indicators|I:)/
         && defined($self->{'color_ds'})) {
            $color = get_color($self->{'color_ds'}->get($i));

            #print STDERR ">>> @$color\n";
        }

        if ($y > $yc_max) {
          $y = $yc_max;
          $tooshort = 1;
        # mark clip at zone bottom
        } elsif ($y < $yc_min) {
          $y = $yc_min;
          $tooshort = -1;
        } else {
          $tooshort = 0;
        }

        if ($y > $yc_zero) {
            $driver->filled_rectangle($picture, 
                $zone->absolute_coordinate($x, $yc_zero),
                $zone->absolute_coordinate($x + $space - 2, $y),
                $color);
        } else {
            $driver->filled_rectangle($picture, 
                $zone->absolute_coordinate($x, $y),
                $zone->absolute_coordinate($x + $space - 2, $yc_zero),
                $color);
        }
        #
        # this puts a ^/v marker at top/bot of bar if it is clipped
        #
        if ( $tooshort != 0 ) {
            my $inverse = [];
            my @points = ();
            if ( ! $self->{'inverse'} ) {
                $inverse = $self->{'clip_color'};
            } else {
            foreach ( 0..$#$color ) {
                $inverse->[$_] = 255 - $color->[$_]
                  unless ($_ > 2);
            }
            }
            if ( $tooshort > 0 ) {
                @points = (
                    [$zone->absolute_coordinate($x + int($space / 2) - 1, $y)],
                    [$zone->absolute_coordinate($x, $y - $space)],
                    [$zone->absolute_coordinate($x + $space - 2, $y - $space)]
            );
            } else {
                @points = (
                    [$zone->absolute_coordinate($x + int($space / 2) - 1, $y)],
                    [$zone->absolute_coordinate($x, $y + $space)],
                    [$zone->absolute_coordinate($x + $space - 2, $y + $space)]
                );
            }
            $driver->filled_polygon($picture, $inverse, @points);
        }
    }
}


sub set_foreground_color {
    my ($self, $color) = @_;
    if ( $self->{'calc'} ne "" && $color =~ /^\s*(Indicators|I:)/ ) {
      $self->{'fg_color'} = $color;
      $self->{'color_ds'} =
       GT::Graphics::DataSource::GenericIndicatorResults->new($self->{'calc'}, $color );
    }
    else {
      $self->{'fg_color'} = get_color($color);
    }
}


1;
