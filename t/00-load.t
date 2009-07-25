#!perl -T

use Test::More tests => 1;

BEGIN {
	use_ok( 'Finance::GeniusTrader' );
}

diag( "Testing Finance::GeniusTrader $Finance::GeniusTrader::VERSION, Perl $], $^X" );
