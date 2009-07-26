#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';
use lib '../..';
use lib '../../..';

use strict;
use vars qw($db);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Calculator;
use Finance::GeniusTrader::Eval;
use Getopt::Long;

=head1 ./test_indicator.pl [ --full ] [ --last-record ] [ --verbose ] <indicatorname> <code> [args...]

Examples:
./test_indicator.pl SMA IBM [100]
./test_indicator.pl --full RSI 13000

Args are passed to the new call that will create the indicator.

=cut

# Get all options
my ($code, $with_interval) = ('', 1);
GetOptions('code=s' => \$code, "interval!" => \$with_interval);

# Create the indicator according to the arguments
my $indicator_module = shift;
my $indicator = create_standard_object("Indicators::$indicator_module",
					@ARGV);

# Create the framework
my $db = create_standard_object("DB::Text");
$db->set_directory("data");

my $indicator_name = $indicator->get_name;
my $q = $db->get_prices($code);
my $calc = Finance::GeniusTrader::Calculator->new($q);

$calc->set_code($code);
my $last = $q->count() - 1;
my $first = 0;

# Computations
if ($with_interval) {
    $indicator->calculate_interval($calc, $first, $last);
} else {
    Finance::GeniusTrader::Indicators::calculate_interval($indicator, $calc, $first, $last);
}

print "# Results for $indicator_module @ARGV\n";
my @names = ();
for(my $n = 0; $n < $indicator->get_nb_values; $n++) {
    push @names, $indicator->get_name($n);
}
print join("\t", "# YYYY-MM-DD", @names) . "\n";
my $format = join("\t", ("%-10s") x scalar(@names));
for(my $i = $first; $i <= $last; $i++)
{
    my @values = ();
    foreach my $name (@names) {
	if ($calc->indicators->is_available($name, $i)) {
	    push @values, sprintf("%.4f", $calc->indicators->get($name, $i));
	} else {
	    push @values, "-";
	}
    }
    printf "%-10s\t$format\n", $q->at($i)->[$DATE], @values;
}

$db->disconnect;

