#!/usr/bin/perl -w
use strict;
use Finance::GeniusTrader::DateTime;
use Finance::GeniusTrader::Calculator;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Test
    tests => 23,
    gt_config => sub {
        my $test_base = shift;
        my $db_path = File::Spec->catdir($test_base, 'data');
<<"EOF";
DB::module Text
DB::text::file_extension _\$timeframe.txt
DB::text::directory $db_path
EOF
    };

# 5min
{
    my ($calc, $first, $last) = Finance::GeniusTrader::Tools::find_calculator(Finance::GeniusTrader::Test->gt_db, 'TX', $PERIOD_5MIN, 1);

    ok($calc);
    is($first, 0);
    is($last, 179);
    is($calc->prices->count, 180);
    is($calc->prices->at(179)->[$DATE], '2009-10-05 13:45:00');
    ok( !$calc->prices->has_date('2009-10-05 08:45:00') );
    ok( $calc->prices->has_date('2009-10-05 08:50:00') );
    is( $calc->prices->date('2009-10-05 08:45:00'), undef );
    is( $calc->prices->date('2009-10-05 08:50:00'), 120 );
    my $p = $calc->prices->at_date('2009-10-05 08:50:00');
    is( $p->[$DATE], '2009-10-05 08:50:00' );
    is( $p->[$OPEN], 7358);
    is( $p->[$HIGH], 7368);
    is( $p->[$LOW], 7346);
    is( $p->[$CLOSE], 7355);
}

# day
{
    my ($calc, $first, $last) = Finance::GeniusTrader::Tools::find_calculator(Finance::GeniusTrader::Test->gt_db, 'TX', $DAY, 1);
    ok($calc);
    is($first, 0);
    is($last, 190);
    is($calc->prices->count, 191);
    is($calc->prices->at(190)->[$DATE], '2009-10-05 00:00:00');
    ok( !$calc->prices->has_date('2009-10-03') );
    ok( $calc->prices->has_date('2009-10-05 00:00:00') );
    is( $calc->prices->date('2009-10-03'), undef );
    is( $calc->prices->date('2009-10-05 00:00:00'), 190 );

}
