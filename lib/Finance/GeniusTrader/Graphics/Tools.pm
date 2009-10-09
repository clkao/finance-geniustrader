package Finance::GeniusTrader::Graphics::Tools;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $PI);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(build_axis_for_timeframe build_axis_for_timeframe2
                build_axis_for_interval get_color
		union_range
	       );
%EXPORT_TAGS = ( "axis"  => [qw(build_axis_for_timeframe
                                build_axis_for_timeframe2
                                build_axis_for_interval
				union_range)],
		 "color" => [qw(get_color)]
	       );

use Finance::GeniusTrader::DateTime;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Graphics::Driver;
#ALL# use Log::Log4perl qw(:easy);

=head1 Finance::GeniusTrader::Graphics::Tools

This modules provides several helper functions that can be used in all
modules.

It provides functions for managing labels on axes that can be imported with
use Finance::GeniusTrader::Graphics::Tools qw(:axis) :

=over 4

=item build_axis_for_timeframe($prices, $timeframe, $put_label, $period)

Create the ticks for a time axis for the given $prices using the indicated
$timeframe. If $put_label then labels we'll be put for each tick. If $period
the label will be the name of the period, otherwise it will be the date
of the first subperiod (usually a day).

=item build_axis_for_interval($min, $max, $many, $label)

Create the ticks between $min and $max for a numeric axis. If $many then
many ticks (~20) will be created otherwise only a few (~5) will be
created. If $label then the ticks will be labelled.

=item ($min, $max) = union_range($min1, $max1, $min2, $max2)

Return the range resulting of the union of the two given ranges.

=back

It provides functions to manage colors. They can be imported with
use Finance::GeniusTrader::Graphics::Tools qw(:color) :

=over 4

=item get_color({$colorname|$color_code})

Return a color. You can ask it by its name ("blue", "light blue", ..) or
by its RGB code "[125,164,198]".

=back

=cut
sub build_axis_for_timeframe {
    my ($prices, $timeframe, $put_label, $period, $space) = @_;
    $period    = 1 if (! defined($period));
    $put_label = 1 if (! defined($put_label));

    #WAR# WARN "new timeframe must be larger" unless ($timeframe > $prices->timeframe);

    my @axis;
    
    my $date = $prices->at(0)->[$DATE];
    my ($prevdate, $newdate);
    $prevdate = Finance::GeniusTrader::DateTime::convert_date($date, $prices->timeframe,
					   $timeframe);
    push @axis, [ 0, $period ? $prevdate : $date ];
    for(my $i = 0; $i < $prices->count; $i++) {
	# Build the date in the new timeframe corresponding to the prices
        # being treated
        $newdate = Finance::GeniusTrader::DateTime::convert_date($prices->at($i)->[$DATE], 
					      $prices->timeframe, $timeframe);
	
        # If the date differs from the previous one then we have completed
        # a new item
        if ($newdate ne $prevdate) {
            # Store the new item
	    push @axis, [ $i, $period ? $newdate : $prices->at($i)->[$DATE] ];
        }

        # Update the previous date
        $prevdate = $newdate;
    }

    # Remove the labels if we don't want labels
    if (! $put_label) { foreach (@axis) { $_->[1] = ""; } }
    my $skip = 0;
    if ( $space ) {
      if ($space < 15) {
	foreach (@axis) { $_->[1] = "" if ($skip%6); $skip++;  }
      } elsif ($space < 20) {
	foreach (@axis) { $_->[1] = "" if ($skip%3); $skip++;  }
      } elsif ($space < 30) { 
	foreach (@axis) { $_->[1] = "" if ($skip%2); $skip++;  }
      }
    }

    return \@axis;
}

sub build_axis_for_timeframe2 {
    my ($prices, $timeframe, $timeframe2) = @_;
    my @axis;
    
    my $date = $prices->at(0)->[$DATE];
    my ($prevdate, $newdate);
    my ($prevdate2, $newdate2);
    $prevdate = Finance::GeniusTrader::DateTime::convert_date($date, $prices->timeframe,
					   $timeframe);
    $prevdate2 = Finance::GeniusTrader::DateTime::convert_date($date, $prices->timeframe,
					   $timeframe2);
    push @axis, [ 0, $prevdate ];
    for(my $i = 0; $i < $prices->count; $i++) {
	# Build the date in the new timeframe corresponding to the prices
        # being treated
        $newdate = Finance::GeniusTrader::DateTime::convert_date($prices->at($i)->[$DATE], 
					      $prices->timeframe, $timeframe);

        $newdate2 = Finance::GeniusTrader::DateTime::convert_date($prices->at($i)->[$DATE], 
                                               $prices->timeframe, $timeframe2);
	
        # If the date differs from the previous one then we have completed
        # a new item
        if ($newdate ne $prevdate) {
            # Store the new item
            my $display = $newdate;
            $display =~ s/^\Q$prevdate2\E//;
            $display =~ s/(\d\d):00(:00)?/$1/;
	    push @axis, [ $i, $display ]
        }

        # Update the previous date
        $prevdate = $newdate;
        $prevdate2 = $newdate2;
    }


    return \@axis;
}

sub build_axis_for_interval {
    my ($min, $max, $many, $label) = @_;
    $many = 0 if (! defined($many));
    $label = 1 if (! defined($label));
    
    sub _label {
	my $a = shift;
	my $b = shift;
	my $p = 0;
	my $sign = 0;
	if ($a < 0) {
	    $a = - $a;
	    $sign = 1
	}

	# Don't ask me why... 
	# otherwise I have 0.1e-18 values i should never see
	if ($a < 10 ** -15) { $a = 0; $sign = 0; }
	
	$p = log($a) / log(10) if ($a > 0);
	if ($p >= 6) {
	    my $digits = $b > 5 ? 1 : 6 - $b;
	    my $formatstr = '%s%.' . $digits . 'fM';
	    return sprintf($formatstr, $sign ? "-" : "", $a / (10 ** 6));
	} elsif ($p >= 3) {
	    my $digits = $b > 2 ? 1 : 3 - $b;
	    my $formatstr = '%s%.' . $digits . 'fk';
	    return sprintf($formatstr, $sign ? "-" : "", $a / (10 ** 3));
	} else {
	    return (($sign ? "-" : "") . $a);
	}
    }

    my $interval;
    if ($many) {
	$interval = ($max - $min) / 20;
    } else {
	$interval = ($max - $min) / 4;
    }
    # Due to rounding small interval may show up negative?
    my $log = ($interval != 0) ? log($interval) / log(10) : 0;
    my $power = int($log - (($log < 0) ? 1.5 : 0.5));
    my $inc = 10 ** $power;
    while ($inc * 5 <= $interval) {
	$inc *= 5;
    }
    while ($inc * 2 <= $interval) {
	$inc *= 2;
    }
    my @res;
    my $start = int($min / $inc + (($min < 0) ? -0.99 : 0.99)) * $inc;
    while ($start < $max) {
	push @res, [ $start, $label ? _label($start,int($log)) : "" ];
	$start += $inc;
    }
    return \@res;
}

sub union_range {
    my ($min1, $max1, $min2, $max2) = @_;
    return ((($min1 < $min2) ? $min1 : $min2),
            (($max1 > $max2) ? $max1 : $max2));
}

sub get_color {
    my ($color) = @_;

    if (ref($color) =~ /ARRAY/) {
	return $color;
    }
    
    if ($color =~ /\[(.*)\]/) {
	return [ split /,/, $1 ];
    }

    $color =~ /white/i && return [255, 255, 255];
    $color =~ /black/i && return [0, 0, 0];
    $color =~ /light.*grey/i && return [196,196,196];
    $color =~ /dark.*grey/i && return [92,92,92];
    $color =~ /grey/i && return [128,128,128];
    $color =~ /light.*red/i && return [255,128,128];
    #$color =~ /dark.*red/i && return [128,0,0];
    $color =~ /red/i && return [255, 0, 0];
    $color =~ /light.*blue/i && return [128, 128, 255];
    $color =~ /dark.*blue/i && return [0, 0, 128];
    $color =~ /blue/i && return [0, 0, 255];
    $color =~ /light.*green/i && return [128, 255, 128];
    #$color =~ /dark.*green/i && return [0, 128, 0];
    $color =~ /green/i && return [0, 255, 0];
    $color =~ /light.*yellow/i && return [255, 255, 128];
    $color =~ /dark.*yellow/i && return [128, 128, 0];
    $color =~ /yellow/i && return [255, 255, 0];
    $color =~ /light.*cyan/i && return [128, 255, 255];
    $color =~ /dark.*cyan/i && return [0, 128, 128];
    $color =~ /cyan/i && return [0, 255, 255];
    $color =~ /light.*purple/i && return [255, 128, 255];
    $color =~ /dark.*purple/i && return [128, 0, 128];
    $color =~ /purple/i && return [255, 0, 255];
    $color =~ /ALICE.*BLUE/i && return [240, 248, 255];
    $color =~ /ANTIQUE.*WHITE/i && return [250, 235, 215];
    $color =~ /AQUAMARINE/i && return [41, 171, 151];
    $color =~ /AZUR/i && return [240, 255, 255];
    $color =~ /BEIGE/i && return [245, 245, 220];
    $color =~ /BISQUE/i && return [255, 228, 196];
    $color =~ /BLACK/i && return [0, 0, 0];
    $color =~ /BLANCHED.*ALMOND/i && return [255, 235, 205];
    $color =~ /BLUE/i && return [0, 0, 255];
    $color =~ /BLUE.*VIOLET/i && return [138, 43, 226];
    $color =~ /BROWN/i && return [103, 67, 0];
    $color =~ /BURYWOOD/i && return [22, 184, 135];
    $color =~ /CADET.*BLUE/i && return [95, 153, 159];
    $color =~ /CHARTREUSE/i && return [127, 255, 0];
    $color =~ /CHOCOLATE/i && return [210, 105, 30];
    $color =~ /CORAL/i && return [248, 137, 117];
    $color =~ /CORNFLOWER.*BLUE/i && return [34, 34, 152];
    $color =~ /CORNSILK/i && return [255, 248, 220];
    $color =~ /CYAN/i && return [0, 255, 255];
    $color =~ /DARK.*BLUE/i && return [0, 0, 139];
    $color =~ /DARK.*CYAN/i && return [0, 139, 139];
    $color =~ /DARK.*GOLDENROD/i && return [184, 134, 11];
    $color =~ /DARK.*GRAY/i && return [169, 169, 169];
    $color =~ /DARK.*GREEN/i && return [0, 83, 0];
    $color =~ /DARK.*KHAKI/i && return [189, 183, 107];
    $color =~ /DARK.*MAGENTA/i && return [139, 0, 139];
    $color =~ /DARK.*OLIVE.*GREEN/i && return [85, 107, 47];
    $color =~ /DARK.*ORANGE/i && return [255, 127, 0];
    $color =~ /DARK.*ORCHID/i && return [153, 50, 204];
    $color =~ /DARK.*RED/i && return [139, 0, 0];
    $color =~ /DARK.*SALMON/i && return [233, 150, 122];
    $color =~ /DARK.*SEA.*GREEN/i && return [143, 188, 143];
    $color =~ /DARK.*SLATE.*BLUE/i && return [72, 61, 139];
    $color =~ /DARK.*SLATE.*GRAY/i && return [47, 79, 79];
    $color =~ /DARK.*TURQUOISE/i && return [0, 195, 205];
    $color =~ /DARK.*VIOLET/i && return [148, 0, 211];
    $color =~ /DEEP.*PINK/i && return [255, 20, 147];
    $color =~ /DEEP.*SKY.*BLUE/i && return [0, 191, 255];
    $color =~ /DIM.*GRAY/i && return [105, 105, 105];
    $color =~ /DODGER.*BLUE/i && return [30, 144, 255];
    $color =~ /FIREBRICK/i && return [136, 18, 13];
    $color =~ /FLAT.*MEDIUM.*BLUE/i && return [58, 95, 205];
    $color =~ /FLAT.*MEDIUM.*GREEN/i && return [143, 188, 143];
    $color =~ /FLORAL.*WHITE/i && return [255, 250, 240];
    $color =~ /FOREST.*GREEN/i && return [34, 139, 34];
    $color =~ /GAINSBORO/i && return [220, 220, 220];
    $color =~ /GHOST.*WHITE/i && return [248, 248, 255];
    $color =~ /GOLD/i && return [254, 197, 68];
    $color =~ /GOLDENROD/i && return [218, 165, 32];
    $color =~ /GRAY/i && return [174, 174, 174];
    $color =~ /GREEN/i && return [0, 255, 0];
    $color =~ /GREEN.*YELLOW/i && return [159, 211, 0];
    $color =~ /HOT.*PINK/i && return [255, 105, 180];
    $color =~ /INDIAN.*RED/i && return [101, 46, 46];
    $color =~ /IVORY/i && return [255, 255, 240];
    $color =~ /KHAKI/i && return [189, 167, 107];
    $color =~ /LAVENDER/i && return [230, 230, 250];
    $color =~ /LAVENDER.*BLUSH/i && return [255, 240, 245];
    $color =~ /LAWN.*GREEN/i && return [124, 252, 0];
    $color =~ /LEMON.*CHIFFON/i && return [255, 250, 205];
    $color =~ /LIGHT.*BLUE/i && return [171, 197, 255];
    $color =~ /LIGHT.*CORAL/i && return [240, 128, 128];
    $color =~ /LIGHT.*CYAN/i && return [224, 255, 255];
    $color =~ /LIGHT.*GOLDENROD/i && return [238, 221, 130];
    $color =~ /LIGHT.*GOLDENROD.*YELLOW/i && return [250, 250, 210];
    $color =~ /LIGHT.*GRAY/i && return [211, 211, 211];
    $color =~ /LIGHT.*GREEN/i && return [144, 238, 144];
    $color =~ /LIGHT.*PINK/i && return [255, 174, 185];
    $color =~ /LIGHT.*SALMON/i && return [255, 160, 122];
    $color =~ /LIGHT.*SEA.*GREEN/i && return [32, 178, 170];
    $color =~ /LIGHT.*SKY.*BLUE/i && return [176, 226, 255];
    $color =~ /LIGHT.*SLATE.*BLUE/i && return [132, 112, 255];
    $color =~ /LIGHT.*SLATE.*GRAY/i && return [119, 136, 153];
    $color =~ /LIGHT.*STEEL.*BLUE/i && return [52, 152, 202];
    $color =~ /LIGHT.*YELLOW/i && return [255, 255, 224];
    $color =~ /LIME.*GREEN/i && return [46, 155, 28];
    $color =~ /LINEN/i && return [250, 240, 230];
    $color =~ /MAGENTA/i && return [255, 0, 211];
    $color =~ /MAROON/i && return [103, 7, 72];
    $color =~ /MEDIUM.*AQUAMARINE/i && return [21, 135, 118];
    $color =~ /MEDIUM.*BLUE/i && return [61, 98, 208];
    $color =~ /MEDIUM.*FOREST.*GREEN/i && return [107, 142, 35];
    $color =~ /MEDIUM.*GOLDENROD/i && return [184, 134, 11];
    $color =~ /MEDIUM.*ORCHID/i && return [172, 77, 166];
    $color =~ /MEDIUM.*PINK/i && return [255, 125, 179];
    $color =~ /MEDIUM.*PURPLE/i && return [147, 112, 219];
    $color =~ /MEDIUM.*SEA.*GREEN/i && return [27, 134, 86];
    $color =~ /SLATE.*BLUE/i && return [95, 109, 154];
    $color =~ /MEDIUM.*SPRING.*GREEN/i && return [60, 141, 35];
    $color =~ /MEDIUM.*TURQUOISE/i && return [62, 172, 181];
    $color =~ /MEDIUM.*VIOLET.*RED/i && return [199, 21, 133];
    $color =~ /MIDNIGHT.*BLUE/i && return [12, 62, 99];
    $color =~ /MINT.*CREAM/i && return [245, 255, 250];
    $color =~ /MISTY.*ROSE/i && return [255, 228, 225];
    $color =~ /MOCCASIN/i && return [255, 228, 181];
    $color =~ /NAVAJO.*WHITE/i && return [255, 222, 173];
    $color =~ /NAVY/i && return [0, 0, 142];
    $color =~ /OLD.*GOLDENROD/i && return [238, 221, 130];
    $color =~ /LACE/i && return [253, 245, 230];
    $color =~ /OLD.*MEDIUM.*GOLDENROD/i && return [238, 238, 175];
    $color =~ /OLIVE.*DRAB/i && return [107, 142, 35];
    $color =~ /ORANGE/i && return [255, 138, 0];
    $color =~ /ORANGE.*RED/i && return [226, 65, 42];
    $color =~ /ORCHID/i && return [218, 107, 212];
    $color =~ /PALE.*GOLDENROD/i && return [238, 232, 170];
    $color =~ /PALE.*GREEN/i && return [152, 255, 152];
    $color =~ /PALE.*PINK/i && return [255, 170, 200];
    $color =~ /PALE.*TURQUOISE/i && return [175, 238, 238];
    $color =~ /PALE.*VIOLET.*RED/i && return [219, 112, 147];
    $color =~ /PAPAYA.*WHIP/i && return [255, 239, 213];
    $color =~ /PEACH.*PUFF/i && return [255, 218, 185];
    $color =~ /PERU/i && return [205, 133, 63];
    $color =~ /PINK/i && return [255, 174, 185];
    $color =~ /PLUM/i && return [76, 46, 87];
    $color =~ /POWDER.*BLUE/i && return [176, 224, 230];
    $color =~ /PURPLE/i && return [138, 43, 226];
    $color =~ /RED/i && return [255, 0, 0];
    $color =~ /ROSY.*BROWN/i && return [188, 143, 143];
    $color =~ /ROYAL.*BLUE/i && return [65, 105, 225];
    $color =~ /SADDLE.*BROWN/i && return [139, 69, 19];
    $color =~ /SALMON/i && return [248, 109, 104];
    $color =~ /SANDY.*BROWN/i && return [178, 143, 86];
    $color =~ /SEA.*GREEN/i && return [43, 167, 112];
    $color =~ /SEASHELL/i && return [255, 245, 238];
    $color =~ /SIENNA/i && return [142, 107, 35];
    $color =~ /SKY.*BLUE/i && return [0, 138, 255];
    $color =~ /SLATE.*BLUE/i && return [117, 134, 190];
    $color =~ /SLATE.*GRAY/i && return [112, 128, 144];
    $color =~ /SNOW/i && return [255, 250, 250];
    $color =~ /SPRING.*GREEN/i && return [0, 255, 159];
    $color =~ /STEEL.*BLUE/i && return [55, 121, 153];
    $color =~ /TAN/i && return [176, 155, 125];
    $color =~ /THISTLE/i && return [146, 62, 112];
    $color =~ /TOMATO/i && return [255, 99, 71];
    $color =~ /TURQUOISE/i && return [72, 209, 204];
    $color =~ /VIOLET/i && return [148, 0, 211];
    $color =~ /VIOLET.*RED/i && return [255, 0, 148];
    $color =~ /WHEAT/i && return [229, 199, 117];
    $color =~ /WHITE/i && return [255, 255, 255];
    $color =~ /WHITE.*SMOKE/i && return [245, 245, 245];
    $color =~ /YELLOW/i && return [255, 255, 0];
    $color =~ /YELLOW.*GREEN/i && return [75, 211, 0];

    return [0, 0, 0];
}

1;
