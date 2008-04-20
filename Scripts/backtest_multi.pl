#!/usr/bin/perl -w

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '/bourse/perl';
use lib '..';
use lib '../..';

#use lib '/tmp';

use strict;

use XML::Simple;
#use Data::Dumper;

use GT::Prices;
use GT::Portfolio;
use GT::PortfolioManager;
use GT::Calculator;
use GT::Report;
use GT::BackTest;
use GT::BackTest::Spool;
use GT::Eval;
use Getopt::Long;
use GT::Conf;
use GT::DateTime;
use GT::Tools qw(:conf :timeframe);
use Pod::Usage;

GT::Conf::load();


# Gestion des options
my ($full, $nb_item, $start, $end, $timeframe, $max_loaded_items) =
   (0, 0, '', '', 'day', -1);
my $man = 0;
my @options;
my ($outputdir, $set) = 
   ('', '');
$outputdir = GT::Conf::get("BackTest::Directory") || '';
GetOptions('full!' => \$full, 'nb-item=i' => \$nb_item, 
	   "start=s" => \$start, "end=s" => \$end, 
	   "max-loaded-items" => \$max_loaded_items,
	   "timeframe=s" => \$timeframe,
	  'output-directory=s' => \$outputdir, 'set=s' => \$set,
	   "option=s" => \@options, "help!" => \$man);
$timeframe = GT::DateTime::name_to_timeframe($timeframe);
my $init = 10000;

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

# read the system-description
my $filename = shift;
my $xs = new XML::Simple( ForceArray => 1,
			  KeyAttr => ['value'] );
my $data = $xs->XMLin( $filename );
#use Data::Dumper;
#print Dumper($data);

# Create the Portfoliomanager
my $pf_manager = GT::PortfolioManager->new;

# Set up the various system managers
my @sys_manager = ();
my @brokers = ();
my $cnt = 0;
foreach my $sm ( @{$data->{'system-manager'}} ) {

  # New manager
  $sys_manager[$cnt] = GT::SystemManager->new;

  # Set the system
  my @systems = keys %{$sm->{'system'}};
  my $system = $systems[0];
  if ( $system =~/^\^/ ) {
    $sys_manager[$cnt]->set_system(create_standard_object(split (/\s+/, "$system")));
  } else {
    $sys_manager[$cnt]->set_system(create_standard_object(split (/\s+/, "Systems::$system")));
  }

  # Add the Orderfactory
  my @ofs = keys %{$sm->{'of'}};
  my $ofname = $ofs[0];
  if ($ofname) {
    $sys_manager[$cnt]->set_order_factory(create_standard_object(split (/\s+/, "OrderFactory::$ofname")));
  }

  # Add the Tradefilter
  my @tfname = keys %{$sm->{'tf'}};
  foreach (@tfname) {
    $sys_manager[$cnt]->add_trade_filter(create_standard_object(split (/\s+/, "TradeFilters::$_")));
  }

  # Add the Tradefilter
  my @csname = keys %{$sm->{'cs'}};
  foreach (@csname) {
    $sys_manager[$cnt]->add_position_manager(create_standard_object(split (/\s+/, "CloseStrategy::$_")));
  }

  # Setting the broker
  my @tbrokers = keys %{$sm->{'broker'}};
  my $broker = $tbrokers[0];
  if ( $broker ) {
    push @brokers, $broker;
  } else {
    push @brokers, '';
  }

  $sys_manager[$cnt]->finalize;
  $cnt++;
}

$init = (keys %{$data->{'init'}})[0];

# Set the Money Management
my @mmname = keys %{$data->{'mm'}};
push @mmname, "Basic" if ($#mmname < 0);
foreach (sort {$data->{'mm'}->{$a}->{sort} <=> $data->{'mm'}->{$b}->{sort}} @mmname) {
  #print STDERR "Adding MM: $_\n";
  $pf_manager->add_money_management_rule(create_standard_object(split (/\s+/, "MoneyManagement::$_")));
}

$pf_manager->default_money_management_rule(
	create_standard_object("MoneyManagement::Basic"));
$pf_manager->finalize;

my @codes = keys %{$data->{'code'}};

# Now the hard part...
my $analysis = backtest_multi($pf_manager, \@sys_manager, \@brokers, \@codes, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items, $init);

# Print the analysis
GT::Report::Portfolio($analysis->{'portfolio'}, 1);
print "## Global analysis (each position is 10keuros, value of portfolio)\n";
GT::Report::PortfolioAnalysis($analysis->{'real'}, 1);
#print "\n## Theoretical analysis (10keuros, full portfolio reinvested)\n";
#GT::Report::PortfolioAnalysis($analysis->{'theoretical'}, $verbose);


if ($set) {
    my $bkt_spool = GT::BackTest::Spool->new($outputdir);
    my $stats = [ $analysis->{'real'}{'std_performance'},
		  $analysis->{'real'}{'performance'},
		  $analysis->{'real'}{'max_draw_down'},
		  $analysis->{'real'}{'std_buyandhold'},
		  $analysis->{'real'}{'buyandhold'}
		];

    delete $analysis->{'portfolio'}->{objects};

    print STDERR $set . " --> " . $filename . "\n";

    $bkt_spool->update_index();
    $bkt_spool->add_alias_name($set."-".$filename, $set);
    $bkt_spool->add_results($set."-".$filename, "MULTI", $stats,
			    $analysis->{'portfolio'}, $set);
    $bkt_spool->sync();
}


