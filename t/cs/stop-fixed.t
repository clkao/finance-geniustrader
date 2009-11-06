#!/usr/bin/perl -w
use strict;
use Finance::GeniusTrader::DateTime;
use Finance::GeniusTrader::Calculator;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::BackTest;
use Finance::GeniusTrader::PortfolioManager;
use Finance::GeniusTrader::SystemManager;
use Finance::GeniusTrader::Tools qw(resolve_alias);
use Finance::GeniusTrader::Test
    tests => 1,
    gt_config => sub {
        my $test_base = shift;
        my $db_path = File::Spec->catdir($test_base, 'data');
<<"EOF";
DB::module Text
DB::text::file_extension _\$timeframe.txt
DB::text::directory $db_path
Brokers::module NoCosts

Aliases::Global::CBBTD[] SY:AlwaysInTheMarket \\
 |OF:ChannelBreakout {I:G:MaxInPeriod #1 {I:Prices HIGH}} \\
                     {I:G:MinInPeriod #2 {I:Prices LOW }} \\
 |CS:ChannelBreakout {I:G:Eval #3} \\
                     {I:G:Eval #4} \\
                      |CS:Stop:Fixed #5|MM:FixedShares 1 \\
 |TF:MaxOpenTrades 1|TF:ShortOnly
EOF
    };

my ($calc, $first, $last) = Finance::GeniusTrader::Tools::find_calculator(Finance::GeniusTrader::Test->gt_db, 'TXExtreme', $PERIOD_5MIN, 0, '2007-08-14 00:00:00', '2007-08-15 00:00:00');

my $pf_manager = Finance::GeniusTrader::PortfolioManager->new;
my $sys_manager = Finance::GeniusTrader::SystemManager->new;
my $sysname = 'CBBTD[60,60,8000,9000,1]';
my $alias = resolve_alias($sysname);
$sys_manager->set_alias_name($sysname);
$sysname = $alias;
$sys_manager->setup_from_name($sysname);
$pf_manager->setup_from_name($sysname);

$pf_manager->finalize;
$sys_manager->finalize;
my $analysis = backtest_single($pf_manager, $sys_manager, undef, $calc, $first, $last);

my $compact = [ map {
        my $details = join( ',', map { $_->{'order'} . $_->price }
                $_->list_detailed_orders );
        [ $_->open_date, $_->close_date, $details ];
} @{ $analysis->{portfolio}{history} } ];

is_deeply($compact,
          [ [
              '2007-08-14 09:25:00',
              '2007-08-14 10:05:00',
              'S8842,B8930.42'
          ]
        ]
      );

