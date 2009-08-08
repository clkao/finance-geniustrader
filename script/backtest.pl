#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw($db);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Portfolio;
use Finance::GeniusTrader::PortfolioManager;
use Finance::GeniusTrader::Calculator;
use Finance::GeniusTrader::Report;
use Finance::GeniusTrader::BackTest;
use Finance::GeniusTrader::Eval;
use Getopt::Long;
use Finance::GeniusTrader::Conf;
use Finance::GeniusTrader::DateTime;
use Finance::GeniusTrader::Tools qw(:conf :timeframe);
use Finance::GeniusTrader::Graphics::DataSource::PortfolioEvaluation;
use Finance::GeniusTrader::Graphics::Driver;
use Finance::GeniusTrader::Graphics::Object;
use Finance::GeniusTrader::Graphics::Graphic;
use Finance::GeniusTrader::Graphics::Tools qw(:axis :color);
use Pod::Usage;

Finance::GeniusTrader::Conf::load();

=head1 ./backtest.pl [ options ] <code>

=head1 ./backtest.pl [ options ] <system_alias> <code>

=head1 ./backtest.pl [ options ] "<full_system_name>" <code>

=head2 Description

Backtest will run a backtest of a system on the indicated code.

You can either describe the system using options, give a full system
name, or you can give a system alias. An alias is defined in the 
configuration file with entries of the form 
 Aliases::Global::<alias_name> <full_system_name>. 

The full system name consists of a set of properties, such as trade 
filters, close strategy, etc., together with their parameters, 
separated by vertical bars ("|"). Multiple properties of the same 
type can be defined, e.g., there could be a set of close strategies.
For example,
  System:ADX 30 | TradeFilters:Trend 2 5 | MoneyManagement:Normal 
defines a system based on the "ADX" system, using a trend following trade
filter "Trend", and the "Normal" money management.

The following abbreviations are supported:
Systems = SY
CloseStrategy = CS
TradeFilters = TF
MoneyManagement = MM
OrderFactory = OF
Signals = S
Indicators = I
Generic = G

Another example of a full system name is 
  SY:TFS|CS:SY:TFS|CS:Stop:Fixed 4|MM:VAR.

=head2 Options

Backtest provide a set of options, so that you can use a combination
of MoneyManagement, TradeFilters, OrderFactory an CloseStrategy modules.

=over 4

=item --full, --start=<date>, --end=<date>, --nb-item=<nr>

Determines the time interval over which to perform the backtest. In detail:

=over

=item --start=2001-1-10, --end=2002-11-17

The start and end dates over which to perform the backtest.
The date needs to be in the
format configured in ~/.gt/options and must match the timeframe selected. 

=item --nb-items=100

The number of periods to use in the analysis.

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

=item --template="backtest.mpl"

Output is generated using the indicated HTML::Mason component.
For Example, --template="backtest.mpl"
The template directory is defined as Template::directory in the options file.
Each template can be predefined by including it into the options file
For example, Template::backtest backtest.mpl

=item --html

Output is generated in html

=item --graph="filename.png"

Generate a graph of your portfolio value over the time of the backtest and
display it in the generated html.

=item --display-trades

Display the trades with little symbols on the graph. This works well if
trades last long enough otherwise your graph will be overwhelmed with
unsignificant symbols.

=item --store="portfolio.xml"

Store the resulting portfolio in the indicated file.

=item --broker="NoCosts"

Calculate commissions and annual account charge, if applicable, using
Finance::GeniusTrader::Brokers::<broker_name> as broker.

=item --system="<system_name>"

use the Finance::GeniusTrader::Systems::<system_name> as the source of buy/sell orders.  

=item --money-management="<money_management_name>" 

use the Finance::GeniusTrader::MoneyManagement::<money_management_name> as money management system.

=item --trade-filter="<filter_name>"

use the Finance::GeniusTrader::TradeFilters::<filter_name> as a trade filter.  

=item --order-factory="<order_factory_name>" 

use Finance::GeniusTrader::OrderFactory::<order_factory_name> as an order factory.  

=item --close-strategy="<close_strategy_name>" 

use Finance::GeniusTrader::CloseStrategy::<close_strategy_name> as a close strategy.

=item --set=SETNAME

Stores the backtest results in the "backtests" directory (refer to your options file for the location of this directory) using the set name SETNAME. Use the --set option of analyze_backtest.pl to differentiate between the different backtest results in your directory.

=item --output-directory=DIRNAME

Override the "backtests" directory in the options file.

=item --verbose

=item --options=<key>=<value>

A configuration option (typically given in the options file) in the
form of a key=value pair. For example,
 --option=DB::Text::format=0
sets the format used to parse markets via the DB::Text module to 0.

=back

=head2 Examples

=over 4

=item

./backtest.pl TFS 13000

=item

./backtest.pl --full TFS 13000

=item

./backtest.pl --close-strategy="Systems::TFS" --close-strategy="Stop::Fixed 6" --money-management="VAR" --money-management="OrderSizeLimit" --system="TFS" --broker="SelfTrade Intégral" 13000

=item

./backtest.pl --broker="SelfTrade Intégral" "SY:TFS|CS:SY:TFS|CS:Stop:Fixed 6|MM:VAR|MM:OrderSizeLimit" 13000

=back

=cut

# Manage options
my ($full, $nb_item, $start, $end, $timeframe, $max_loaded_items) =
   (0, 0, '', '', 'day', -1);
my $man = 0;
my @options;
my ($verbose, $html, $display_trades, $template, $graph_file, $ofname, $broker, $system, $store_file, $outputdir, $set) = 
   (0, 0, 0, '', '', '', '', '', '', '', '');
my (@mmname, @tfname, @csname);
$outputdir = Finance::GeniusTrader::Conf::get("BackTest::Directory") || './';
GetOptions('full!' => \$full, 'nb-item=i' => \$nb_item, 
	   "start=s" => \$start, "end=s" => \$end, 
	   "max-loaded-items=s" => \$max_loaded_items,
	   "timeframe=s" => \$timeframe,
	   'verbose!' => \$verbose, 'html!' => \$html,
	   'template=s' => \$template, 'display-trades!' => \$display_trades,
	   'output-directory=s' => \$outputdir, 'set=s' => \$set,
	   'money-management=s' => \@mmname, 'graph=s' => \$graph_file,
	   'trade-filter=s' => \@tfname, 'order-factory=s' => \$ofname,
	   'close-strategy=s' => \@csname, 'broker=s' => \$broker,
	   'system=s' => \$system, "store=s" => \$store_file,
	   "option=s" => \@options, "help!" => \$man);

foreach (@options) {
    my ($key, $value) = split (/=/, $_);
    Finance::GeniusTrader::Conf::set($key, $value);
}

pod2usage( -verbose => 2) if ($man);

if (! scalar(@mmname))
{
    @mmname = ("Basic");
}
if ($system && ! scalar(@csname)) {
    die "You must give at least one --close-strategy argument !\n";
}

if (! -d $outputdir)
{
  die "The directory '$outputdir' doesn't exist !\n";
}

# Create the entire framework
my $pf_manager = Finance::GeniusTrader::PortfolioManager->new;
my $sys_manager = Finance::GeniusTrader::SystemManager->new;


if ($system) {
    $sys_manager->set_system(
	    create_standard_object(split (/\s+/, "Systems::$system")));
} else {
    my $sysname = shift;
    # Check for alias
    if (! defined($sysname)) {
	die "You must give either a --system parameter or an alias name.";
    }
    if ($sysname !~ /\|/)
    {
	my $alias = resolve_alias($sysname);
	die "Alias unknown '$alias'" if (! $alias);
	$sys_manager->set_alias_name($sysname);
	$sysname = $alias;
    }

    if (defined($sysname) && $sysname)
    {
	$sys_manager->setup_from_name($sysname);
	$pf_manager->setup_from_name($sysname);
    } else {
	die "You must give either a --system parameter or an alias name.";
    }
}

foreach (@mmname)
{
    $pf_manager->add_money_management_rule(
	create_standard_object(split (/\s+/, "MoneyManagement::$_")));
}
$pf_manager->default_money_management_rule(
	create_standard_object("MoneyManagement::Basic"));
$pf_manager->finalize;

if ($ofname)
{
    $sys_manager->set_order_factory(
	create_standard_object(split (/\s+/, "OrderFactory::$ofname")));
}
foreach (@tfname)
{
    $sys_manager->add_trade_filter(
	create_standard_object(split (/\s+/, "TradeFilters::$_")));
}
foreach (@csname)
{
    $sys_manager->add_position_manager(
	create_standard_object(split (/\s+/, "CloseStrategy::$_")));
}
$sys_manager->finalize;

# Prepare data
my $code = shift;
if (! $code) {
    die "You must give a symbol for the simulation.\n";
}

$timeframe = Finance::GeniusTrader::DateTime::name_to_timeframe($timeframe);

# Verify dates and adjust to timeframe, comment out if not desired
check_dates($timeframe, $start, $end);

my $db = create_db_object();

my ($calc, $first, $last) = find_calculator($db, $code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);

# The real work happens here
my $analysis = backtest_single($pf_manager, $sys_manager, $broker, $calc, $first, $last);

if ($store_file) {
    $analysis->{'portfolio'}->store($store_file);
}

if ($graph_file) {
    # create graph for backtested portfolio
    my $graph_ds = Finance::GeniusTrader::Graphics::DataSource::PortfolioEvaluation->new($calc, $analysis->{'portfolio'});
    $graph_ds->set_selected_range($first, $last);

    # create graph for buy and hold portfolio
    my $pf_manager2 = Finance::GeniusTrader::PortfolioManager->new;
    my $sys_manager2 = Finance::GeniusTrader::SystemManager->new;
    $pf_manager2->setup_from_name("SY:AlwaysInTheMarket | TF:LongOnly | TF:OneTrade | CS:NeverClose");
    $sys_manager2->setup_from_name("SY:AlwaysInTheMarket | TF:LongOnly | TF:OneTrade | CS:NeverClose");
    my $def_rule = create_standard_object("MoneyManagement::Basic");
    $pf_manager2->default_money_management_rule($def_rule);
    $pf_manager2->finalize;
    $sys_manager2->finalize;
    my $analysis2 = backtest_single($pf_manager2, $sys_manager2, $broker, $calc, $first, $last);
    my $graph_ds2 = Finance::GeniusTrader::Graphics::DataSource::PortfolioEvaluation->new($calc, $analysis2->{'portfolio'});
    $graph_ds2->set_selected_range($first, $last);

    # set up graphic objects
    my $zone = Finance::GeniusTrader::Graphics::Zone->new(700, 300, 80, 40, 0, 40);
    my $scale = Finance::GeniusTrader::Graphics::Scale->new();
    $scale->set_horizontal_linear_mapping($first, $last + 1, 0, $zone->width);
    $scale->set_vertical_linear_mapping(union_range($graph_ds->get_value_range, $graph_ds2->get_value_range), 0, $zone->height);
    $zone->set_default_scale($scale);
    my $axis_h = Finance::GeniusTrader::Graphics::Axis->new($scale);
    my $axis_v = Finance::GeniusTrader::Graphics::Axis->new($scale);
    $axis_h->set_custom_big_ticks(build_axis_for_interval(union_range($graph_ds->get_value_range, $graph_ds2->get_value_range), 0, 1));
    $axis_v->set_custom_big_ticks(build_axis_for_timeframe($calc->prices(), $YEAR, 1, 1), 1);
    $zone->set_axis_left($axis_h);
    $zone->set_axis_bottom($axis_v);
    my $graphic = Finance::GeniusTrader::Graphics::Graphic->new($zone);
    my $graph = Finance::GeniusTrader::Graphics::Object::Curve->new($graph_ds, $zone);
    $graph->set_foreground_color([0, 190, 0]);
    $graph->set_antialiased(0);
    my $graph2 = Finance::GeniusTrader::Graphics::Object::Curve->new($graph_ds2, $zone);
    $graph2->set_foreground_color([190, 0, 0]);
    $graph2->set_antialiased(0);
    $graphic->add_object($graph2);
    $graphic->add_object($graph);
    if ($display_trades) {
	my $trades = Finance::GeniusTrader::Graphics::Object::Trades->new($calc, $zone,
							$analysis->{'portfolio'},
							$first, $last);
	$graphic->add_object($trades);
    }

    my $driver = create_standard_object("Graphics::Driver::GD");
    my $picture = $driver->create_picture($zone);
    $graphic->display($driver, $picture);
    $driver->save_to($picture, $graph_file);
}

# Display the results
$template = Finance::GeniusTrader::Conf::get('Template::backtest') if ($template eq '');
if (defined($template) && $template ne '') {
  my $output;

  my $use = 'use HTML::Mason;use File::Spec;use Cwd;';
  eval $use;
  die($@) if($@);

  my $root = Finance::GeniusTrader::Conf::get('Template::directory');
  $root = File::Spec->rel2abs( cwd() ) if (!defined($root));
  my $interp = HTML::Mason::Interp->new( comp_root => $root,
					 out_method => \$output
				       );
  $template='/' . $template unless ($template =~ /\\|\//);
  $interp->exec($template, analysis => $analysis, 
	  sys_manager => $sys_manager, pf_manager => $pf_manager, 
	  verbose => $verbose);
  print $output;
}
elsif ($html)
{
    print "Analysis of " . $sys_manager->get_name . "|" .
	$pf_manager->get_name;
    if ($graph_file) {
        print "<h2>Value of portfolio (green) vs. buy and hold (red)</h2>\n";
    	print "<img src=\"$graph_file\" alt=\"Portfolio evaluation\" \\>\n";
    }
    print "<table border='1' bgcolor='#EEEEEE'><tr><td>";
    print "<pre>";
    print "## Global analysis (full portfolio always invested)\n";
    Finance::GeniusTrader::Report::PortfolioAnalysis($analysis->{'real'}, $verbose);
    print "</pre></td></tr></table>";
    Finance::GeniusTrader::Report::PortfolioHTML($analysis->{'portfolio'}, $verbose);
}
else
{
    print "## Analysis of " . $sys_manager->get_name . "|" .
	$pf_manager->get_name . "\n";
    Finance::GeniusTrader::Report::Portfolio($analysis->{'portfolio'}, $verbose);
    print "## Global analysis (full portfolio always invested)\n";
    Finance::GeniusTrader::Report::PortfolioAnalysis($analysis->{'real'}, $verbose);
    print "\n";
}

$db->disconnect;

if ( $set ) {
  # Store intermediate result
  my $bkt_spool = Finance::GeniusTrader::BackTest::Spool->new($outputdir);
  my $stats = [ $analysis->{'real'}{'std_performance'},
		$analysis->{'real'}{'performance'},
		$analysis->{'real'}{'max_draw_down'},
		$analysis->{'real'}{'std_buyandhold'},
		$analysis->{'real'}{'buyandhold'}
	      ];

  $bkt_spool->update_index();
  $bkt_spool->add_alias_name($sys_manager->get_name, $sys_manager->alias_name);
  $bkt_spool->add_results($sys_manager->get_name, $code, $stats,
			  $analysis->{'portfolio'}, $set);
  $bkt_spool->sync();
}
