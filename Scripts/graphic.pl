#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;
use vars qw($db);

use GT::Prices;
use GT::Calculator;
use GT::Conf;
use GT::Eval;
use GT::Graphics::Driver;
use GT::Graphics::DataSource;
use GT::Graphics::Object;
use GT::Graphics::Graphic;
use GT::Graphics::Tools qw(:axis :color);
use GT::BackTest::Spool;
use GT::Portfolio;
use GT::DateTime;
use GT::Tools qw(:conf :timeframe);
use Getopt::Long 2.33;
use Pod::Usage;

GT::Conf::load();

=head1 ./graphic.pl [ options | additional graphical elements ] <code>

=head2 Synopsis

./graphic.pl [ --timeframe=timeframe ] [ --nb-item=100 ] \
		    [ --start=2005-06-01 ] [ --end=2006-01-01 ] \
		    [ --type=candle|candlevol|candlevolplace|barchart|line|none ] [ --volume ]
		    [ --volume-height=150 ] [ --title="Daily Chart" ] \
		    [ --width=200 ] [ --height=230 ] [ --logarithmic ] \
		    [ additional graphical elements ] \
                    [ --file=conf ] [ --driver={GD|ImageMagick} ] \
		    <code>

Use "graphic.pl --man" to list all available options


=head2 Description

graphic.pl can generate charts in png format, including indicators and system signals,
either as overlays of the original price data, or in different regions of the chart.

Various options are available to control color, size and other graphic properties.

=head2 Additional Graphical Elements

=over 4

By default, only the price will be plotted, however, you can add other indicators,
either as overlays or in different zones of the chart.

To plot overlays, simply add them to the graphic. For instance:

--add="Curve(Indicators::EMA 50, blue)"
--add="Curve(Indicators::EMA 200, red)"

To plot indicators in a different zone, first create a new-zone, then add the indicators:

  --add="New-Zone(100)"
  --add="Histogram(I:MACD/3, brown)"

  --add="New-Zone(100)"
  --add="Curve(I:MACD/1, red)"
  --add="Curve(I:MACD/2, green)"


  --add="New-Zone(100)"
  --add="Set-Scale(0,100)" --add="set-title(RSI,tiny)" \
  --add="Curve(Indicators::RSI/3)"

Full details about the available methods you can use with the --add option follow.

Note that all objects that might affect the scale (such as, e.g., an
indicator) must be added to a zone before the scale is changed.


=item New-Zone(height, [left, right, top, bottom])

This creates a new zone for displaying more indicators. It's created with
the given height and the given border sizes.

=item Switch-Zone(zoneid)

This changes the current display zone. 0 is the main zone, 1 is the volume
zone if it exists. 2 is the first indicator zone and so on. Usually you just
need to it switch to the "Volume" zone because you start on the main zone
and you automatically switch to any newly created zone.

=item Set-Scale(min,max,[logarithmic]) or Set-scale(auto,[logarithmic])

This defines the scale for the currently selected zone (by default the last
zone created or the main zone if no zone has been created). If auto scale
is used, the scale must be set after all objects that can affect the min or
max values have been added.

=item Set-Special-Scale(min,max,[log]) or Set-Special-Scale(auto,[log])

The last created object will be displayed with its own scale (and not the
default one of the zone). The scale may be given or it may be calculated
to fit the full zone. If auto scale is used, the scale must be set after 
all objects that can affect the min or max values have been added.

=item Set-Axis(tick1,tick2,tick3...)

Define the ticks for the main axis of the current zone.

=item Set-Title{-left|-right|-top|-bottom}(title,font_size)

This adds a title to the currently selected zone. The title will be displayed
in the given size (size can be tiny, small, medium, large and giant).
If the title contains a %c, this is replaced by the <code>, if it contains
%n, this is replaced by the long name of the <code>. See also 
~/.gt/sharenames, which contains lines of the form
<code>\t<long name>
mapping a market to its long name.

=item Histogram(<datasource>, [color])

=item Curve(<datasource>, [color])

=item Marks(<datasource>, [color])

=item Mountain(<datasource>, [color])

=item MountainBand(<datasource1>, <datasource2>, [color])

This adds a new graphical object in the current zone. The datasource explains
what data has to be displayed.

=item Text(text, x, y, [halign, valign, font_size, color, font_face])

This adds a block of text at the given coordinate (expressed in percent
of the width/height of the zone).

halign can be one of "left", "center" or "right". valign can be one of
"top", "bottom" or "center". font_size can be one of "tiny", "small",
"medium", "large" or "giant". font_face can be one of "arial", "times" or
"fixed".

=item BuySellArrows(Systems::...)

This adds buy and sell arrows in the main chart, based on systems signals.

=item VotingLine(Systems::..., [y])

Show buy and sell arrows in a Voting Line à la OmniTrader, based on a System
Manager. You can indicate the y at which the line should be displayed.

=back

=head2 Datasources

Sometimes you need to pass datasources to the graphical objects. The
following are currently available.

=over 4

=item Indicators::<indicatorname>

An indicator.

=item PortfolioEvaluation(<portfolio>)

This datasources returns the evaluation of any portfolio.

=back

=head2 Other Objects

Some datasources may be parameterized by objects. The following are
currently available.

=over 4

=item BackTestPortfolio(<systemname>, [directory])

This returns a portfolio that has been saved for a backtest of the
system "systemname". The given directory must be a spool
of backtests.

=back

=head2 Options

=over 4

=item --full, --start=<date>, --end=<date>, --nb-item=<nr>

Determines the time interval used to plot the graphics. In detail:

=over

=item --start=2001-1-10, --end=2002-11-17

The start and end dates considered for the plot. The date needs to be in the
format configured in ~/.gt/options and must match the timeframe selected. 

=item --nb-items=100

The number of periods to use to plot the graphics. Default is 120.

=item --full

Consider all available periods.

=back

The periods considered are relative to the selected time frame (i.e., if timeframe
is "day", these indicate a date; if timeframe is "week", these indicate a week;
etc.). In GT format, use "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss" for days (the
latter giving intraday data), "YYYY-WW" for weeks, "YYYY/MM" for months, and 
"YYYY" for years.

The interval of periods examined is determined as follows:

=over

=item 1 if present, use --start and --end (otherwise default to last price)

=item 1 use --nb-item (from first or last, whichever has been determined), 
if present

=item 1 if --full is present, use first or last price, whichever has not yet been determined

=item 1 otherwise, consider a two year interval.

=back

The first period determined following this procedure is chosen. If additional
options are given, these are ignored (e.g., if --start, --end, --full are given,
--full is ignored).

=item --timeframe=1min|5min|10min|15min|30min|hour|3hour|day|week|month|year

The timeframe can be any of the available modules in GT/DateTime.  

=item --max-loaded-items

Determines the number of periods (back from the last period) that are loaded
for a given market from the data base. Care should be taken to ensure that
these are consistent with the performed analysis. If not enough data is
loaded to satisfy dependencies, for example, correct results cannot be obtained.
This option is effective only for certain data base modules and ignored otherwise.

=item --type=candle|candlevol|candlevolplace|barchart|line|none

The type of graphic to plot. none causes the price not to be displayed,
however, overlays can still be sketched in the graphic.

=item --volume

Should the volume be plotted (it is by default)? Use --no-volume if you
want to omit it.

=item --volume-height=150

=item --title="Daily Chart"

=item --width=200

=item --height=230

=item --logarithmic

=item --driver=GD|ImageMagick

=item --options=<key>=<value>

A configuration option (typically given in the options file) in the
form of a key=value pair. For example,
 --option=DB::Text::format=0
sets the format used to parse markets via the DB::Text module to 0.

=item Configuration-File ( --file=conf )

With this option, additional parameters are read from the
configurationfile conf. Each line in this file corresponds to a
command line parameter. Lines starting with # are ignored.

=back

=head2 Examples

./graphic.pl --add="Switch-Zone(0)" \
             --add="Curve(Indicators::SMA  38, [0,0,255])" \
             --add="Curve(Indicators::SMA 100, [0,255,0])" \
             --add="Curve(Indicators::SMA 200, [255,0,0])" \
             --title="Daily history of %c" \
             13000 > test.png

./graphic.pl --add="Curve(Indicators::EMA 5,[255,0,0])" \
             --add="Curve(Indicators::EMA 20,[0,0,255])" \
             --add="BuySellArrows(SY::Generic {S::Generic::CrossOverUp {I:EMA 5} {I:EMA 20}} {S::Generic::CrossOverDown {I:EMA 5} {I:EMA 20}} )" \
             13000 > test.png

=cut

# Get all options
my $nb_item = GT::Conf::get('Option::nb-item');
$nb_item = (defined($nb_item))?$nb_item:120;
my ($full, $start, $end, $timeframe, $max_loaded_items) =
   (0, '', '', 'day', -1);
my ($width, $height) = ("", "200");
my $type = "candle";
my $volume = 1;
my $logarithmic = 0;
my $vheight = 50;
my @add;
my @options;
my $title = '';
my $filename = "";
my $opt_driver = "";
my $man = 0;

Getopt::Long::Configure("pass_through","auto_help");
GetOptions("file=s" => \$filename );

if ( open(CONF, "<$filename") ) {
    while(<CONF>)
    {
	chomp;
	s/^\s*//;
	s/\s*$//;
	push @ARGV, $_ unless /^#/;
    }
    close CONF;  
}

Getopt::Long::Configure("no_pass_through");
GetOptions('full!' => \$full, 'nb-item=i' => \$nb_item, 
	   "start=s" => \$start, "end=s" => \$end, 
	   "max-loaded-items=s" => \$max_loaded_items,
	   "timeframe=s" => \$timeframe,
	   "width=i" => \$width, "height=i" => \$height,
	   "type=s" => \$type, "volume!" => \$volume,
	   "volume-height=s" => \$vheight,
	   "logarithmic!" => \$logarithmic, "add=s" => \@add,
	   "option=s" => \@options, "title=s" => \$title,
	   "file=s" => \$filename, "driver=s" => \$opt_driver,
	   "man!" => \$man);
$timeframe = GT::DateTime::name_to_timeframe($timeframe);

foreach (@options) {
    my ($key, $value) = split (/=/, $_);
    GT::Conf::set($key, $value);
}

# Verify dates and adjust to timeframe, comment out if not desired
check_dates($timeframe, $start, $end);

pod2usage( -verbose => 2) if ($man);
my $code = shift || pod2usage(1);

my $db = create_db_object();

my ($calc, $first, $last) = find_calculator($db, $code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);
$nb_item = $last - $first + 1;

GT::Conf::default("Graphics::Driver", "GD");
if ($opt_driver) {
    GT::Conf::set("Graphics::Driver", $opt_driver);
}
    
my $driver = create_standard_object("Graphics::Driver::" . GT::Conf::get("Graphics::Driver"));

#my $driver = GT::Graphics::Driver::GD->new();
#my $driver = GT::Graphics::Driver::ImageMagick->new();

# Création des zones
if (! $width) {
    $width = $nb_item * GT::Conf::get("Graphic::Candle::Width");
}

my $y_zone = 0;
my $zone = GT::Graphics::Zone->new($width, 200, 40, 40, 40, 40);
my $z_m = GT::Graphics::Zone->new($width, $height);
$zone->add_subzone(0, $y_zone++, $z_m);

my $graphic = GT::Graphics::Graphic->new($zone);
my $q = $calc->prices();

if ($volume and ($type ne "none")) {
    my $z_v = GT::Graphics::Zone->new($width, $vheight);
    $zone->add_subzone(0, $y_zone++, $z_v);
    my $ds_v = GT::Graphics::DataSource::Volume->new($q);
    $ds_v->set_selected_range($first, $last);
    my $scale_v = GT::Graphics::Scale->new();
    $scale_v->set_horizontal_linear_mapping($first, $last + 1, 
					    0, $z_v->width());
    $scale_v->set_vertical_linear_mapping(0, ($ds_v->get_value_range())[1],
					  0, $z_v->height());
    $z_v->set_default_scale($scale_v);
    my $axis_v = GT::Graphics::Axis->new($scale_v);
    $axis_v->set_custom_big_ticks(
	    build_axis_for_interval(0, ($ds_v->get_value_range())[1], 0, 1)
	);
    $axis_v->set_custom_ticks([]);
    $z_v->set_axis_left($axis_v);
    my $vol = GT::Graphics::Object::Histogram->new($ds_v, $z_v, $calc);
    my $vol_color = GT::Conf::get('Graphic::Volume::Color');
    $vol->set_foreground_color($vol_color) if (defined($vol_color));

    $graphic->add_object($vol);
}

$zone->update_size();

$zone->set_border_width(1);
if ($title) { 
    my $longname = get_long_name($code);
    $title =~ s/%c/$code/;
    $title =~ s/%n/$longname/;
    $zone->set_title_top($title);
} else {
    my $longname = get_long_name($code);
    if ($longname) {
	$zone->set_title_top("$longname - $code");
    } else {
	$zone->set_title_top("$code");
    }
}
$zone->set_title_font_size($FONT_SIZE_LARGE);

# Création des sources de données
my $ds = GT::Graphics::DataSource::Prices->new($q);
$ds->set_selected_range($first, $last);
my $ds_c = GT::Graphics::DataSource::Close->new($q);
$ds_c->set_selected_range($first, $last);

# Création des échelles et des axes
my $scale_m = GT::Graphics::Scale->new();
$scale_m->set_horizontal_linear_mapping($first, $last + 1, 0, $z_m->width());
if ($logarithmic) {
    $scale_m->set_vertical_logarithmic_mapping($ds->get_value_range(), 
				      0, $z_m->height());
} else {
    $scale_m->set_vertical_linear_mapping($ds->get_value_range(), 
				      0, $z_m->height());
}
$z_m->set_default_scale($scale_m) if ($type ne "none");

my $axis = GT::Graphics::Axis->new($scale_m);
my $axis2 = GT::Graphics::Axis->new($scale_m);
$axis2->set_grid_level(2)
    if $timeframe <= $PERIOD_5MIN;
$axis->set_custom_big_ticks(
	build_axis_for_interval($ds->get_value_range(), 0, 1)
    );
$axis->set_custom_ticks(
	build_axis_for_interval($ds->get_value_range(), 1, 0)
    );

if ($timeframe <= $PERIOD_1MIN) {
	$axis2->set_custom_ticks(build_axis_for_timeframe2($q, $PERIOD_15MIN, $DAY), 0);
} elsif ($timeframe <= $PERIOD_5MIN) {
	$axis2->set_custom_ticks(build_axis_for_timeframe2($q, $HOUR, $DAY), 0);
} elsif ($timeframe < $DAY) {
	$axis2->set_custom_ticks(build_axis_for_timeframe($q, $DAY, 1), 0);
} elsif ($timeframe == $DAY) {
    my $space = $scale_m->convert_to_x_coordinate(
	    int(GT::DateTime::timeframe_ratio($MONTH, $timeframe))
	) - $scale_m->convert_to_x_coordinate(0);
    if ($space <= 10) {
	$axis2->set_custom_big_ticks(
		build_axis_for_timeframe($q, $YEAR, 1, 1, $space * 12), 1
	    );
    } else {
	$axis2->set_custom_big_ticks(
		build_axis_for_timeframe($q, $MONTH, 1, 1, $space), 1
	    );
	$axis2->set_custom_ticks(build_axis_for_timeframe($q, $WEEK, 0), 1);
    }
} elsif ($timeframe == $WEEK) {
    my $space = $scale_m->convert_to_x_coordinate(
	    int(GT::DateTime::timeframe_ratio($MONTH, $timeframe))
	) - $scale_m->convert_to_x_coordinate(0);
    if ($space <= 5) {
	$axis2->set_custom_big_ticks(
		build_axis_for_timeframe($q, $YEAR, 1, 1, $space * 20), 1
	    );
    } else {
	$axis2->set_custom_big_ticks(
		build_axis_for_timeframe($q, $MONTH, 1, 1, $space), 1
	    );
    }
    #$axis2->set_custom_ticks(build_axis_for_timeframe($q, $WEEK, 0), 1);
} elsif ($timeframe == $MONTH) {
    $axis2->set_custom_big_ticks(build_axis_for_timeframe($q, $YEAR, 1, 1), 1);
    #$axis2->set_custom_ticks(build_axis_for_timeframe($q, $WEEK, 0), 1);
}

$z_m->set_axis_left($axis);
$zone->set_axis_bottom($axis2);

# Création des objets graphiques principaux
if ($type eq "candle") {
    my $candle = GT::Graphics::Object::Candle->new($ds, $z_m);
    $graphic->add_object($candle);
} elsif ($type eq "candlevol") {
    my $bc = GT::Graphics::Object::CandleVolume->new($ds, $z_m);
    $graphic->add_object($bc);
} elsif ($type eq "candlevolplace") {
    my $bc = GT::Graphics::Object::CandleVolumePlace->new($ds, $z_m);
    $graphic->add_object($bc);
} elsif ($type eq "barchart") {
    my $bc = GT::Graphics::Object::BarChart->new($ds, $z_m);
    $graphic->add_object($bc);
} elsif ($type eq "line") {
    my $line = GT::Graphics::Object::Curve->new($ds_c, $z_m);
    $graphic->add_object($line);
} elsif ($type eq "none") {
    # Nothing
} else {
    die "Bad type ($type). Can be candle, candlevol, candlevolplace, barchart, line or none.\n";
}

my @datasource;
my $k = 0;
my $curr_zone = $z_m;
my @curr_range = $type eq "none" ? undef : $ds->get_value_range();
my $last_zone_y = 2;

# Update the scale of the zone to match the given range
# Use a logarithmic scale if $log
# If $special put the axis on the right and apply the special scale to $object
sub update_scale {
    my ($zone, $min, $max, $log, $special, $object) = @_;
    $log = 0 if (! defined($log));
    $special = 0 if (! defined($special));

    if (defined($min) and defined($max)) {
    my $args = GT::ArgsTree->new( $min );
    unless ($args->is_constant(1)) {
      my $ob = $args->get_arg_object(1);
      $ob->calculate($calc, $last)
	if ( $ob->isa("GT::Indicators") );
      my $val = $args->get_arg_values($calc, $last, 1);
      if (defined($val)) {
	$min = $val;
      } else {
	$min = 0;
      }
    }

    $args = GT::ArgsTree->new( $max );
    unless ($args->is_constant(1)) {
      my $ob = $args->get_arg_object(1);
      $ob->calculate($calc, $last)
	if ( $ob->isa("GT::Indicators") );
      my $val = $args->get_arg_values($calc, $last, 1);
      if (defined($val)) {
	$max = $val;
      } else {
	$max = 0;
      }
    }
    }

    my $sc = GT::Graphics::Scale->new;
    $sc->copy_horizontal_scale($scale_m);
    if (defined($min) and defined($max)) {
	if ($log) {
	    $sc->set_vertical_logarithmic_mapping($min, $max, 0, 
						  $zone->height - 1);
	} else {
	    $sc->set_vertical_linear_mapping($min, $max, 0, $zone->height - 1);
	}
    }
    if ($special) {
	$object->set_special_scale($sc);
    } else {
	$zone->set_default_scale($sc);
    }
    my $axis = GT::Graphics::Axis->new($sc);
    if (defined($min) and defined($max)) {
	$axis->set_custom_big_ticks(build_axis_for_interval($min, $max));
    } else {
	$axis->set_custom_big_ticks([]);
    }
    $axis->set_custom_ticks([]);
    if ($special) {
	$axis->set_grid_level(0);
	$zone->set_axis_right($axis);
    } else {
	$zone->set_axis_left($axis);
    }
}

sub update_curr_range {
    my ($s, $e) = @_;
    if ( defined($curr_range[0]) ) { # for some unknown reason, defined($curr_range) is true
	@curr_range = union_range(@curr_range, $s, $e);
    } else {
	@curr_range = ( $s, $e );
    }
}
    
my ($object, $last_obj);
foreach (@add) {
    my ($func, @args) = split_object_desc($_);
    $object = undef;

    if ($func =~ /New-?Zone/i) {
	# Update the scale of the old zone if needed
	if (! defined($curr_zone->get_default_scale())) {
	    update_scale($curr_zone, @curr_range);
	}
	# Create the new zone
	my $new_zone = GT::Graphics::Zone->new($z_m->width, @args);
	$zone->add_subzone(0, $last_zone_y++, $new_zone);
	$curr_zone = $new_zone;
	@curr_range = undef;
	$zone->update_size();
    } elsif ($func =~ /Switch-?Zone/i) {
	# Update the scale of the old zone if needed
	if (! defined($curr_zone->get_default_scale())) {
	    update_scale($curr_zone, @curr_range);
	}
	# Switch to the new zone
	$curr_zone = $zone->get_subzone(0, $args[0]);
	my $scale = $curr_zone->get_default_scale();
	my ($min, $max) = (($scale->get_value_from_coordinate(0, 0))[1],
	    ($scale->get_value_from_coordinate(0, $curr_zone->height - 1))[1]);
	@curr_range = ( $min, $max );
    } elsif ($func =~ /Set-?Scale/i) {
	if ($args[0] =~ /auto/i) {
	    if (defined($args[1]) && $args[1]) {
		update_scale($curr_zone, @curr_range, 1);
	    } else {
		update_scale($curr_zone, @curr_range, 0);
	    }
	} else {
	    @curr_range = ( $args[0], $args[1] );
	    if (defined($args[2]) && $args[2]) {
		update_scale($curr_zone, @curr_range, 1);
	    } else {
		update_scale($curr_zone, @curr_range, 0);
	    }
	}   
    } elsif ($func =~ /Set-?Special-?Scale/i) {
	if ($args[0] =~ /auto/i) {
	    if (defined($args[1]) && $args[1]) {
		update_scale($curr_zone, $last_obj->get_source->get_value_range,
			     1, 1, $last_obj);
	    } else {
		update_scale($curr_zone, $last_obj->get_source->get_value_range,
			     0, 1, $last_obj);
	    }
	} else {
	    if (defined($args[2]) && $args[2]) {
		update_scale($curr_zone, $args[0], $args[1], 1, 1, $last_obj);
	    } else {
		update_scale($curr_zone, $args[0], $args[1], 0, 1, $last_obj);
	    }
	}
    } elsif ($func =~ /Set-?Axis/i) {
	my $axis = GT::Graphics::Axis->new($curr_zone->get_default_scale());
	my @ticks;
	foreach (@args) { push @ticks, [ $_, $_ ]; }
	$axis->set_custom_big_ticks(\@ticks);
	$axis->set_custom_ticks([]);
	$curr_zone->set_axis_left($axis);
    } elsif ($func =~ /Set-?Title-?(\w+)?/i) {
	my $where = $1 || '';
	$args[1] ||= '';
	if ($args[1] =~ /tiny/i) {
	    $curr_zone->set_title_font_size($FONT_SIZE_TINY);
	} elsif ($args[1] =~ /small/i) {
	    $curr_zone->set_title_font_size($FONT_SIZE_SMALL);
	} elsif ($args[1] =~ /medium/i) {
	    $curr_zone->set_title_font_size($FONT_SIZE_MEDIUM);
	} elsif ($args[1] =~ /large/i) {
	    $curr_zone->set_title_font_size($FONT_SIZE_LARGE);
	} elsif ($args[1] =~ /giant/i) {
	    $curr_zone->set_title_font_size($FONT_SIZE_GIANT);
	} else {
	    $curr_zone->set_title_font_size($FONT_SIZE_SMALL);
	}
	if (defined($args[2]) && $args[2]) {
	    $curr_zone->set_title_font_color(get_color($args[2]));
	}
        if ($where =~ /top/i) {
	    $curr_zone->set_title_top($args[0]);
	} elsif ($where =~ /bottom/i) {
	    $curr_zone->set_title_bottom($args[0]);
	} elsif ($where =~ /left/i) {
	    $curr_zone->set_title_left($args[0]);
	} elsif ($where =~ /right/i) {
	    $curr_zone->set_title_right($args[0]);
	} else {
	    $curr_zone->set_title_top($args[0]);
	}
    } elsif ($func =~ /Histogram/i) {
	my $ds_i = build_datasource($args[0], $calc, $first, $last);
	update_curr_range($ds_i->get_value_range());
	$object = GT::Graphics::Object::Histogram->new($ds_i, $curr_zone, $calc);
	$object->set_foreground_color($args[1]) if (defined($args[1]));
    } elsif ($func =~ /Curve/i) {
	my $ds_i = build_datasource($args[0], $calc, $first, $last);
	update_curr_range($ds_i->get_value_range());
	$object = GT::Graphics::Object::Curve->new($ds_i, $curr_zone);
	if ($func !~ /EquityCurve/i) {
	    $object->set_foreground_color($args[1]) if (defined($args[1]));
	} else {
	    $object = GT::Graphics::Object::Mountain->new($ds_i, $curr_zone);
	    $object->set_foreground_color($args[2]) if (defined($args[2]));
	}
    } elsif ($func =~ /Marks/i) {
	my $ds_i = build_datasource($args[0], $calc, $first, $last);
	update_curr_range($ds_i->get_value_range());
	$object = GT::Graphics::Object::Marks->new($ds_i, $curr_zone);
	$object->set_foreground_color($args[1]) if (defined($args[1]));
    } elsif ($func =~ /MountainBand/i) {
	my $ds_i = build_datasource($args[0], $calc, $first, $last);
	update_curr_range($ds_i->get_value_range());
	my $ds_i2 = build_datasource($args[1], $calc, $first, $last);
	update_curr_range($ds_i2->get_value_range());
	$object = GT::Graphics::Object::MountainBand->new($ds_i, $curr_zone, $ds_i2);
	$object->set_foreground_color($args[2]) if (defined($args[2]));
    } elsif ($func =~ /Mountain/i) {
	my $ds_i = build_datasource($args[0], $calc, $first, $last);
	update_curr_range($ds_i->get_value_range());
	$object = GT::Graphics::Object::Mountain->new($ds_i, $curr_zone);
	$object->set_foreground_color($args[1]) if (defined($args[1]));
    } elsif ($func =~ /Text/i) {
	my ($text, $x, $y, $h, $v, $s, $c, $f) = @args;
	$object = GT::Graphics::Object::Text->new($text, $curr_zone, $x, $y,
						  $h, $v);
	if (defined($s)) {
	    ($s =~ /tiny/i) && ($object->set_font_size($FONT_SIZE_TINY));
	    ($s =~ /small/i) && ($object->set_font_size($FONT_SIZE_SMALL));
	    ($s =~ /medium/i) && ($object->set_font_size($FONT_SIZE_MEDIUM));
	    ($s =~ /large/i) && ($object->set_font_size($FONT_SIZE_LARGE));
	    ($s =~ /giant/i) && ($object->set_font_size($FONT_SIZE_GIANT));
	}
	$object->set_foreground_color($c) if (defined($c));
	if (defined($f)) {
	    ($f =~ /arial/i) && ($object->set_font_face($FONT_ARIAL));
	    ($f =~ /times/i) && ($object->set_font_face($FONT_TIMES));
	    ($f =~ /fixed/i) && ($object->set_font_face($FONT_FIXED));
	}
    } elsif ($func =~ /Polygon/i) {
	$object = GT::Graphics::Object::Polygon->new($calc, $curr_zone, \@args);
    } elsif ($func =~ /BuySellArrows/i) {
	my $ds_s = build_datasource($args[0], $calc, $first, $last);
	$object = GT::Graphics::Object::BuySellArrows->new($ds_s, 
							   $curr_zone, $ds);
    } elsif ($func =~ /VotingLine/i) {
	my $ds_s = build_datasource(shift @args, $calc, $first, $last);
	$object = GT::Graphics::Object::VotingLine->new($ds_s,
							$curr_zone, @args);
    }
    # Add the object if required
    if (defined($object)) {
	$graphic->add_object($object);
	$last_obj = $object;
    }
}

# Mise à jour de l'échelle de la dernière zone si nécessaire
if (! defined($curr_zone->get_default_scale())) {
    update_scale($curr_zone, @curr_range);
}


my $bottomtext = GT::Graphics::Object::Text->new("Created with GeniusTrader: www.geniustrader.org", 
		    $zone, 99 + 100 * 40 / $zone->width(), 1 - 100 * 40 / $zone->height(), 
		    "right", "bottom");
$bottomtext->set_font_size($FONT_SIZE_TINY);
$bottomtext->set_font_face($FONT_ARIAL);
$graphic->add_object($bottomtext);

# Création du graphiqe
my $picture = $driver->create_picture($zone);
$graphic->display($driver, $picture);
$driver->dump($picture);

$db->disconnect;


# This functions get in input a string like "Object(arg1,arg2,Arg3)"
# where each arg may itself be an Object with its own argument. It
# returns the object name followed by all the arguments.
sub split_object_desc {
    my ($desc) = @_;
    my ($name, @args);
    # Get the object name (and the string describing the arguments)
    if ($desc =~ /^\s*([^(\s]+)\s*\(\s*(.*)\s*\)\s*$/) {
	$name = $1;
	$desc = $2;
	my ($open_sq_bracket, $open_bracket, $open_quote) = (0, 0, 0);
	my $string = "";
	foreach (split(/([[\](),"])/, $desc)) {
	    # Count brackets and square brackets
	    $open_sq_bracket++ if ($_ eq '[');
	    $open_sq_bracket-- if ($_ eq ']');
	    $open_bracket++ if ($_ eq '(');
	    $open_bracket-- if ($_ eq ')');
	    # Count quotes
	    if ($_ eq '"') {
		$open_quote = ! $open_quote; # Switch between 0 and 1
		next; # Don't store quotes
	    }
	    # Split on comma only if neither brackets nor quotes are open
	    if ($_ eq ",") {
		if ($open_quote) {
		    $string .= $_;
		    next;
		}
		if (($open_sq_bracket == 0) and ($open_bracket == 0)) {
		    push @args, $string;
		    $string = "";
		    next;
		}
	    }
	    # Accumulate the string
	    $string .= $_;
	}
	push @args, $string if length($string);
    } else {
	warn "$desc is not a valid object description";
    }
    return ($name, @args);
}

# This function returns the datasource built from the description of it
sub build_datasource {
    my ($desc, $calc, $first, $last) = @_;
    
    my $ds;

    # Try aliases
    if ($desc !~ /^(I|Indicators|SY|Systems|PortfolioEvaluation)/i) {
#	my $alias = resolve_alias($desc);
	my $alias = resolve_object_alias(long_name($desc));

	if (! $alias) {
	  warn "Unknown datasource: $desc\n";
	  return $ds;
	}
	$desc = $alias;
    }

    if ($desc =~ /^(I|Indicators)::?/i) {
	$ds = GT::Graphics::DataSource::SingleIndicator->new($calc, $desc);
	$ds->set_selected_range($first, $last);
    } elsif ($desc =~ /^(SY|Systems)::?/i) {
	my @params = split /\s+/, $desc;
	$desc =	shift @params;
	my $system = create_standard_object($desc, @params);
	if ($#params == -1) { $system = create_standard_object($desc); }
	$ds = GT::Graphics::DataSource::Systems->new($calc, $system);
	$ds->set_selected_range($first, $last);
    } elsif ($desc =~ /^PortfolioEvaluation/i) {
	my ($name, @args) = split_object_desc($desc);
	my $portfolio = build_object($args[0]);
        $ds = GT::Graphics::DataSource::PortfolioEvaluation->new($calc, 
								 $portfolio);
	$ds->set_selected_range($first, $last);
    } else {
	warn "Unknown datasource: $desc\n";
    }
    return $ds;
}

# This function builds various objects (that may be used by datasources
# or whatever) according to their descriptions
sub build_object {
    my ($name, @args) = split_object_desc(@_);
    
    if ($name =~ /BackTestPortfolio/i) {

	# BackTestPortfolio(sysname,directory)
	# BackTestPortfolio(sysname)
	
	my $directory;
        if (defined($args[1]) && $args[1]) {
            $directory = $args[1];
        } elsif (GT::Conf::get("BackTest::Directory")) {
            $directory = GT::Conf::get("BackTest::Directory");
        }

	if (! (defined($directory) && $args[0])) {
	    die "Bad syntax for BackTestPortfolio(sysname, directory) !\n";
	}
	
        my $spool = GT::BackTest::Spool->new($directory);
        return $spool->get_portfolio($args[0], $code);
	
    } else {
	warn "Unknown object type : $name\n";
    }
}
