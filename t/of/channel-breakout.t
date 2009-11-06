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
 |CS:ChannelBreakout {I:G:MinInPeriod #3 {I:Prices LOW }} \\
                     {I:G:MaxInPeriod #4 {I:Prices HIGH}} \\
                      |CS:Stop:Fixed #5|MM:FixedShares 1 \\
 |TF:MaxOpenTrades 1
EOF
    };

my ($calc, $first, $last) = Finance::GeniusTrader::Tools::find_calculator(Finance::GeniusTrader::Test->gt_db, 'TX', $DAY, 1);

my $pf_manager = Finance::GeniusTrader::PortfolioManager->new;
my $sys_manager = Finance::GeniusTrader::SystemManager->new;

my $sysname = 'CBBTD[15,15,5,5,2]';
my $alias = resolve_alias($sysname);
$sys_manager->set_alias_name($sysname);
$sysname = $alias;
$sys_manager->setup_from_name($sysname);
$pf_manager->setup_from_name($sysname);

$pf_manager->finalize;
$sys_manager->finalize;

my $analysis = backtest_single($pf_manager, $sys_manager, undef, $calc, $first+15, $last);

my $compact = [ map {
        my $details = join( ',', map { $_->{'order'} . $_->price }
                $_->list_detailed_orders );
        [ $_->open_date, $_->close_date, $details ];
} @{ $analysis->{portfolio}{history} } ];

is_deeply( $compact,
    [
          [
            '2009-02-11 00:00:00',
            '2009-02-12 00:00:00',
            'B4552,S4460.96'
          ],
          [
            '2009-02-13 00:00:00',
            '2009-02-17 00:00:00',
            'B4578,S4486.44'
          ],
          [
            '2009-03-03 00:00:00',
            '2009-03-03 00:00:00',
            'S4270,B4355.4'
          ],
          [
            '2009-03-05 00:00:00',
            '2009-04-17 00:00:00',
            'B4590,S5696'
          ],
          [
            '2009-05-04 00:00:00',
            '2009-05-12 00:00:00',
            'B6363,S6412'
          ],
          [
            '2009-05-19 00:00:00',
            '2009-05-20 00:00:00',
            'B6720,S6585.6'
          ],
          [
            '2009-05-25 00:00:00',
            '2009-05-26 00:00:00',
            'B6804,S6667.92'
          ],
          [
            '2009-05-27 00:00:00',
            '2009-06-04 00:00:00',
            'B6837,S6700.26'
          ],
          [
            '2009-06-09 00:00:00',
            '2009-06-11 00:00:00',
            'S6402,B6530.04'
          ],
          [
            '2009-06-15 00:00:00',
            '2009-06-24 00:00:00',
            'S6335,B6294'
          ],
          [
            '2009-07-02 00:00:00',
            '2009-07-13 00:00:00',
            'B6558,S6527'
          ],
          [
            '2009-07-15 00:00:00',
            '2009-08-04 00:00:00',
            'B6778,S6870'
          ],
          [
            '2009-08-20 00:00:00',
            '2009-09-01 00:00:00',
            'S6702,B6827'
          ],
          [
            '2009-09-03 00:00:00',
            '2009-09-23 00:00:00',
            'B7112,S7375'
          ]
]);
