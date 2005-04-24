#!/usr/bin/perl -w

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '/bourse/perl';
use lib '..';
use lib '../..';

#use lib '/tmp';

use strict;
use vars qw($db);

use XML::Simple;
use Data::Dumper;

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
use GT::BackTest::SpoolNew;

GT::Conf::load();


# Gestion des options
my ($full, $start, $end, $timeframe, $outputdir, $alias) = 
   (0, '', '', '', '', '');
GetOptions('full!' => \$full, "timeframe=s" => \$timeframe,
	   'start=s' => \$start, 'end=s' => \$end,
	  'output-directory=s' => \$outputdir, 'alias=s' => \$alias );
my $init = 10000;

# read the system-description
my $filename = shift;
my $xs = new XML::Simple( ForceArray => 1,
			  KeyAttr => ['value'] );
my $data = $xs->XMLin( $filename );
#use Data::Dumper;
#print Dumper($data);

# Create the Portfoliomanager and the database
my $db = create_standard_object("DB::" . GT::Conf::get("DB::module"));
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

# Set up the codes
my @codes = keys %{$data->{'code'}};
my @calc = ();
$cnt = 0;
foreach my $code ( @codes ) {
  my $q = $db->get_prices($code);
  $calc[$cnt] = GT::Calculator->new($q);
  $calc[$cnt]->set_code($code);
  if ($timeframe) {
    if (! $calc[$cnt]->set_current_timeframe(GT::DateTime::name_to_timeframe($timeframe))) {
      die "Can't create � $timeframe � timeframe ...\n";
    }
  }
  $cnt++;
}


# Now the hard part...
my $analysis = backtest_multi($pf_manager, \@sys_manager, \@brokers, \@calc, $start, $end, $full, $init);

# Print the analysis
GT::Report::Portfolio($analysis->{'portfolio'}, 1);
print "## Global analysis (each position is 10keuros, value of portfolio)\n";
GT::Report::PortfolioAnalysis($analysis->{'real'}, 1);
#print "\n## Theoretical analysis (10keuros, full portfolio reinvested)\n";
#GT::Report::PortfolioAnalysis($analysis->{'theoretical'}, $verbose);


if ($outputdir ne '') {
    my $bkt_spool = GT::BackTest::SpoolNew->new($outputdir);
    my $stats = [ $analysis->{'real'}{'std_performance'},
		  $analysis->{'real'}{'performance'},
		  $analysis->{'real'}{'max_draw_down'},
		  $analysis->{'real'}{'std_buyandhold'},
		  $analysis->{'real'}{'buyandhold'}
		];

    $alias = "MULTI" if ( $alias eq '' );

    delete $analysis->{'portfolio'}->{objects};

    print STDERR $alias . " --> " . $filename . "\n";
    $bkt_spool->add_alias_name($alias."-".$filename, $alias);

    $bkt_spool->add_results($alias."-".$filename, "GDAXI", $stats,
			    $analysis->{'portfolio'}, $alias);
    $bkt_spool->sync();
}

$db->disconnect;

