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
use GT::Tools qw(:conf);
use Getopt::Long;

GT::Conf::load();

=head1 ./backtest_many.pl [ options ] <market file> <system file>

=head2 Description

Backtest_many will test all system listed in a system
file on all the values listed in the market file.

The "system file" does have a special format.

System::ADX 30 | TradeFilters::Trend 2 5 | MoneyManagement::Normal 

Systems = S
CloseStrategy = CS
TradeFilters = TF
MoneyManagement = MM
OrderFactory = OF

=head2 Options

=over 4

=item --full

Runs the backtest on the full history (it runs on two years by default)

=item --timeframe="day|week|month|year"

Runs the backtest using the given timeframe.

=item --nbprocess=2

If you want to start two  (or more) backtests in parallel (useful for machines with several CPUs for example).

=item --set=SETNAME

Stores the backtest results in the "backtests" directory (refer to your options file for the location of this directory) using the set name SETNAME. Use the --set option of analyze_backtest.pl to differentiate between the different backtest results in your directory.

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
my ($full, $verbose, $broker, $timeframe, $start, $end, $outputdir, $set, $nbprocess) = 
   (0, 0, '', '', '', '', '.', '', 1);
$outputdir = GT::Conf::get("BackTest::Directory") || '';
GetOptions('full!' => \$full, 'verbose' => \$verbose, 
	   'timeframe=s' => \$timeframe, "start=s" => \$start,
	   "end=s" => \$end, 'output-directory=s' => \$outputdir, 
	   'broker=s' => \$broker, 'set=s' => \$set,
	   'nbprocess=s' => \$nbprocess);

# Checks
if (! -d $outputdir)
{
    die "The directory '$outputdir' doesn't exist !\n";
}

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

    my $db = create_standard_object("DB::" . GT::Conf::get("DB::module"));
    my $q = $db->get_prices($code);
    my $calc = GT::Calculator->new($q);
    $calc->set_code($code);

    if ($timeframe)
    {
	$calc->set_current_timeframe(
	            GT::DateTime::name_to_timeframe($timeframe));
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

