#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;
use vars qw($db);

use GT::Prices;
use GT::Portfolio;
use GT::PortfolioManager;
use GT::Calculator;
use GT::Report;
use GT::BackTest;
use GT::BackTest::Spool;
use GT::List;
use GT::Eval;
use GT::Conf;
use GT::DateTime;
use GT::Tools qw(:conf :timeframe);
use Getopt::Long;
use Pod::Usage;

GT::Conf::load();

=head1 ./backtest_many.pl [ options ] <market file> <system file>

=head2 Description

Backtest_many will test all system listed in a system
file on all the values listed in the market file.

The <system file> contains one line per defined system, where each
system is defined by its full system name or by an alias. An alias is 
defined in the configuration file with entries of the form 
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

=over 4

=item --full, --start=<date>, --end=<date>, --nb-item=<nr>

Determines the time interval to consider for analysis. In detail:

=over

=item --start=2001-1-10, --end=2002-11-17

The start and end dates considered for analysis. The date needs to be in the
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

=item --broker="NoCosts"

Calculate commissions and annual account charge, if applicable, using
GT::Brokers::<broker_name> as broker.

=item --nbprocess=2

If you want to start two  (or more) backtests in parallel (useful for machines with several CPUs for example).

=item --set=SETNAME

Stores the backtest results in the "backtests" directory (refer to your options file for the location of this directory) using the set name SETNAME. Use the --set option of analyze_backtest.pl to differentiate between the different backtest results in your directory.

=item --options=<key>=<value>

A configuration option (typically given in the options file) in the
form of a key=value pair. For example,
 --option=DB::Text::format=0
sets the format used to parse markets via the DB::Text module to 0.

=back

=head2 Examples

=over 4

=item
./backtest_many.pl ../Listes/fr/CAC40 ../BackTest/HCB.txt --output-dir=../BackTest/ --set=HCB --full

=back

=head2 Example of system description

SY:TFS 50 7|CS:SY:TFS 50|CS:Stop:Fixed 6|MM:VAR 10 2|MM:PositionSizeLimit 100

=cut

# Manage options
my ($full, $nb_item, $start, $end, $timeframe, $max_loaded_items) =
   (0, 0, '', '', 'day', -1);
my $man = 0;
my @options;
my ($verbose, $broker, $outputdir, $set, $nbprocess) = 
   (0, '', '', '', 1);
$outputdir = GT::Conf::get("BackTest::Directory") || '';
GetOptions('full!' => \$full, 'nb-item=i' => \$nb_item, 
	   "start=s" => \$start, "end=s" => \$end, 
	   "max-loaded-items" => \$max_loaded_items,
	   "timeframe=s" => \$timeframe,
	   'verbose' => \$verbose, 'output-directory=s' => \$outputdir, 
	   'broker=s' => \$broker, 'set=s' => \$set,
	   'nbprocess=s' => \$nbprocess,
	   "option=s" => \@options, "help!" => \$man);
$timeframe = GT::DateTime::name_to_timeframe($timeframe);

foreach (@options) {
    my ($key, $value) = split (/=/, $_);
    GT::Conf::set($key, $value);
}

pod2usage( -verbose => 2) if ($man);

# Checks
if (! -d $outputdir)
{
    die "The directory '$outputdir' doesn't exist !\n";
}

# Verify dates and adjust to timeframe, comment out if not desired
check_dates($timeframe, $start, $end);

# Create all the framework
my $list = GT::List->new;
my $file = shift;
if (! -e $file)
{
    die "File $file doesn't exist.\n";
}
$list->load($file);
my $bkt_spool = GT::BackTest::Spool->new($outputdir);

# Build the list of systems to test
my @desc_systems = <>;
my $systems = {};
foreach my $line (@desc_systems) 
{
    chomp($line);
    
    my $pf_manager = GT::PortfolioManager->new;
    my $sys_manager = GT::SystemManager->new;

    # Aliases
    if ($line !~ /\|/)
    {
	my $alias = resolve_alias($line);
	die "Alias unknown '$alias'" if (! $alias);
	$sys_manager->set_alias_name($line);
	$line = $alias;
    }

    $pf_manager->setup_from_name($line);
    $sys_manager->setup_from_name($line);
    
    my $def_rule = create_standard_object("MoneyManagement::Basic");
    $pf_manager->default_money_management_rule($def_rule);

    $pf_manager->finalize;
    $sys_manager->finalize;

    # Associate systems and managers
    $systems->{$line}{"pf_manager"} = $pf_manager;
    $systems->{$line}{"sys_manager"} = $sys_manager;
}

# Actually launch the backtests
my $analysis;
my $count_process = 0;
for (my $d = 0; $d < $list->count; $d++)
{
    if (fork())
    {
	$count_process++;
	next if ($count_process < $nbprocess);
	wait;
	$count_process--;
	next;
    }
    my $code = $list->get($d);

    my $db = create_db_object();

    my ($calc, $first, $last) = find_calculator($db, $code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);

    # Fork a process to avoid memory consumption
    foreach (@desc_systems)
    {
	my $sys_manager = $systems->{$_}{'sys_manager'};
	my $pf_manager = $systems->{$_}{'pf_manager'};
	
	# Au boulot
	$analysis = backtest_single($pf_manager, $sys_manager, $broker, 
			$calc, $first, $last);

	# Affichage des résultats
	print "##\n## ANALYSIS OF $code with system\n## $_\n##\n";

	#GT::Report::Portfolio($analysis->{'portfolio'}, $verbose);
	print "## Global analysis (full portfolio invested)\n";
	GT::Report::PortfolioAnalysis($analysis->{'real'}, $verbose);

	# Store intermediate result
	my $stats = [ $analysis->{'real'}{'std_performance'},
		      $analysis->{'real'}{'performance'},
		      $analysis->{'real'}{'max_draw_down'},
		      $analysis->{'real'}{'std_buyandhold'},
		      $analysis->{'real'}{'buyandhold'}
		    ];

	$bkt_spool->update_index();
	$bkt_spool->add_alias_name($_, $sys_manager->alias_name);
	$bkt_spool->add_results($_, $code, $stats,
				$analysis->{'portfolio'}, $set);
	$bkt_spool->sync();
    }

    $db->disconnect;

    # Close the child 
    exit 0;
}

# Wait last processes
while ($count_process > 0) {
    wait;
    $count_process--;
}

