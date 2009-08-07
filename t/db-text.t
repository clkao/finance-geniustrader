#!perl

use strict;
use warnings;
use Test::More tests=>5;

BEGIN {
  use_ok( 'Finance::GeniusTrader::Eval' );
  use_ok( 'Finance::GeniusTrader::DB::Text' );
  use_ok( 'Finance::GeniusTrader::Prices' );
}

my $db = create_standard_object("DB::Text");
$db->set_directory("t/data");

my $quotes = $db->get_prices("alcatel") ; # loads day prices from alcatel.txt in a Finance::GeniusTrader::Prices object

ok ( $quotes->has_date('2002-07-31 00:00:00') ) ;
ok ( $quotes->at_date('2002-07-31 00:00:00')->[$OPEN] == 5.38 ) ; # test if OPEN is correct data

