#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;
use vars qw($db);

use Carp::Datum (":all", defined($ENV{'GTDEBUG'}) ? "on" : "off");
use GT::Prices;
use GT::Portfolio;
use GT::PortfolioManager;
use GT::Calculator;
use GT::Report;
use GT::BackTest;
use GT::Eval;
use Getopt::Long;
use GT::Conf;
use GT::DateTime;
use GT::Tools qw(:conf);
use GT::Graphics::DataSource::PortfolioEvaluation;
use GT::Graphics::Driver;
use GT::Graphics::Object;
use GT::Graphics::Graphic;
use GT::Graphics::Tools qw(:axis :color);

GT::Conf::load();

=head1 ./backtest.pl [ options ] <code>

=head1 ./backtest.pl <system_alias> <code>

=head2 Description

Backtest will run a backtest of the system called systemname
(available as GT::Systems::<systemname>) on share of indicated code.

You can either describe the full system with all the options, or you can
give an alias of a system. The alias is set your configuration file with
entries like "Aliases::<alias_name> <full_system_name>". The full
system name is like "SY:TFS|CS:SY:TFS|CS:Stop:Fixed 4|MM:VAR".

=head2 Options

Backtest provide a set of options, so that you can use a combination
of MoneyManagement, TradeFilters, OrderFactory an CloseStrategy modules.

=over 4

=item --full 

Runs the backtest on the full history (it runs on two years by default) 

=item --template="backtest.mpl"

Output is generated using the indicated HTML::Mason component.

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

=item --timeframe="day|week|month|year"

Launch the system while using the indicated timeframe.

=item --system="<system_name>"

use the GT::Systems::<system_name> as the source of buy/sell orders.  

=item --money-management="<money_management_name>" 

use the GT::MoneyManagement::<money_management_name> as money management system.

=item --trade-filter="<filter_name>"

use the GT::TradeFilters::<filter_name> as a trade filter.  

=item --order-factory="<order_factory_name>" 

use GT::OrderFactory::<order_factory_name> as an order factory.  

=item --close-strategy="<close_strategy_name>" 

use GT::CloseStrategy::<close_strategy_name> as a close strategy.

=back

=head2 Examples

=over 4

=item

./backtest.pl TFS 13000

=item

./backtest.pl --full TFS 13000

=item

./backtest.pl --close-strategy="Systems::TFS" --close-strategy="Stop::Fixed 6" --money-management="VAR" --money-management="SizeLimit" --system="TFS" --broker="SelfTrade Intégral" 13000

=back

=cut

# Manage options
my ($full, $verbose, $html, $display_trades, $template, $graph_file, $ofname, $broker, $system, $timeframe, $start, $end, $store_file) = 
   (0, 0, 0, 0, '', '', '', '', '', '', '', '', '');
my (@mmname, @tfname, @csname);
GetOptions('full!' => \$full, 'verbose!' => \$verbose, 'html!' => \$html,
	   'template=s' => \$template, 'display-trades!' => \$display_trades,
	   'money-management=s' => \@mmname, 'graph=s' => \$graph_file,
	   'trade-filter=s' => \@tfname, 'order-factory=s' => \$ofname,
	   'close-strategy=s' => \@csname, 'broker=s' => \$broker,
	   'system=s' => \$system, "timeframe=s" => \$timeframe,
	   'start=s' => \$start, 'end=s' => \$end, "store=s" => \$store_file);

if (! scalar(@mmname))
{
    @mmname = ("Basic");
}
if ($system && ! scalar(@csname)) {
    die "You must give at least one --close-strategy argument !\n";
}

# Create the entire framework
my $db = create_db_object();
my $pf_manager = GT::PortfolioManager->new;
my $sys_manager = GT::SystemManager->new;


if ($system) {
    $sys_manager->set_system(
	    create_standard_object(split (/\s+/, "Systems::$system")));
} else {
    my $alias = shift;
    if (! defined($alias)) {
	die "You must give either a --system parameter or an alias name.";
    }
    my $sysname = resolve_alias($alias);
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
my $q = $db->get_prices($code);
$db->disconnect;

my $calc = GT::Calculator->new($q);
$calc->set_code($code);

if ($timeframe)
{
    if (! $calc->set_current_timeframe(
	    GT::DateTime::name_to_timeframe($timeframe)))
    {
	die "Can't create « $timeframe » timeframe ...\n";
    }
}

my $c = $calc->prices->count;
my $last = $c - 1;
my $first = $c - 2 * GT::DateTime::timeframe_ratio($YEAR, 
						   $calc->current_timeframe);
$first = 0 if ($full);
$first = 0 if ($first < 0);
if ($start) {
    my $date = $calc->prices->find_nearest_following_date($start);
    $first = $calc->prices->date($date);
}
if ($end) {
    my $date = $calc->prices->find_nearest_preceding_date($end);
    $last = $calc->prices->date($date);
}

# The real work happens here
my $analysis = backtest_single($pf_manager, $sys_manager, $broker, $calc, $first, $last);

if ($store_file) {
    $analysis->{'portfolio'}->store($store_file);
}

if ($graph_file) {
    # create graph for backtested portfolio
    my $graph_ds = GT::Graphics::DataSource::PortfolioEvaluation->new($calc, $analysis->{'portfolio'});
    $graph_ds->set_selected_range($first, $last);

    # create graph for buy and hold portfolio
    my $pf_manager2 = GT::PortfolioManager->new;
    my $sys_manager2 = GT::SystemManager->new;
    $pf_manager2->setup_from_name("SY:AlwaysInTheMarket | TF:LongOnly | TF:OneTrade | CS:NeverClose");
    $sys_manager2->setup_from_name("SY:AlwaysInTheMarket | TF:LongOnly | TF:OneTrade | CS:NeverClose");
    my $def_rule = create_standard_object("MoneyManagement::Basic");
    $pf_manager2->default_money_management_rule($def_rule);
    $pf_manager2->finalize;
    $sys_manager2->finalize;
    my $analysis2 = backtest_single($pf_manager2, $sys_manager2, $broker, $calc, $first, $last);
    my $graph_ds2 = GT::Graphics::DataSource::PortfolioEvaluation->new($calc, $analysis2->{'portfolio'});
    $graph_ds2->set_selected_range($first, $last);

    # set up graphic objects
    my $zone = GT::Graphics::Zone->new(700, 300, 80, 40, 0, 40);
    my $scale = GT::Graphics::Scale->new();
    $scale->set_horizontal_linear_mapping($first, $last + 1, 0, $zone->width);
    $scale->set_vertical_linear_mapping(union_range($graph_ds->get_value_range, $graph_ds2->get_value_range), 0, $zone->height);
    $zone->set_default_scale($scale);
    my $axis_h = GT::Graphics::Axis->new($scale);
    my $axis_v = GT::Graphics::Axis->new($scale);
    $axis_h->set_custom_big_ticks(build_axis_for_interval(union_range($graph_ds->get_value_range, $graph_ds2->get_value_range), 0, 1));
    $axis_v->set_custom_big_ticks(build_axis_for_timeframe($q, $YEAR, 1, 1), 1);
    $zone->set_axis_left($axis_h);
    $zone->set_axis_bottom($axis_v);
    my $graphic = GT::Graphics::Graphic->new($zone);
    my $graph = GT::Graphics::Object::Curve->new($graph_ds, $zone);
    $graph->set_foreground_color([0, 190, 0]);
    $graph->set_antialiased(0);
    my $graph2 = GT::Graphics::Object::Curve->new($graph_ds2, $zone);
    $graph2->set_foreground_color([190, 0, 0]);
    $graph2->set_antialiased(0);
    $graphic->add_object($graph2);
    $graphic->add_object($graph);
    if ($display_trades) {
	my $trades = GT::Graphics::Object::Trades->new($calc, $zone,
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
$template = GT::Conf::get('Template::backtest') if (!defined($template));
if ($template ne '') {
  my $output;

  my $use = 'use HTML::Mason;use File::Spec;use Cwd;';
  eval $use;
  die(@!) if(@!);

  my $root = GT::Conf::get('Template::directory');
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
    GT::Report::PortfolioAnalysis($analysis->{'real'}, $verbose);
    print "</pre></td></tr></table>";
    GT::Report::PortfolioHTML($analysis->{'portfolio'}, $verbose);
}
else
{
    print "## Analysis of " . $sys_manager->get_name . "|" .
	$pf_manager->get_name . "\n";
    GT::Report::Portfolio($analysis->{'portfolio'}, $verbose);
    print "## Global analysis (full portfolio always invested)\n";
    GT::Report::PortfolioAnalysis($analysis->{'real'}, $verbose);
    print "\n";
}
