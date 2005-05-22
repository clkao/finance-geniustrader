#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;
use vars qw($db);

use GT::Prices;
use GT::Calculator;
use GT::Report;
use GT::Conf;
use GT::Eval;
use Getopt::Long;

GT::Conf::load();

=head1 ./test_indicator.pl [ --full ] [ --last-record ] [ --verbose ] <indicatorname> <code> [args...]

Examples:
./test_indicator.pl I:SMA IBM 100
./test_indicator.pl --full I:RSI 13000

Args are passed to the new call that will create the indicator.

=cut

# Get all options
my ($full, $last_record, $verbose, $start, $end) = 
    (0, 0, '', '', '');
Getopt::Long::Configure("require_order");
GetOptions('full!' => \$full, "last-record" => \$last_record, 
	   "verbose" => \$verbose, "start=s" => \$start, "end=s" => \$end);

# Create the indicator according to the arguments
my $indicator_module = shift;
my $code = shift;

my $indicator = create_standard_object("$indicator_module",
					@ARGV);

# Il faut créer tout le framework
my $db = create_standard_object("DB::" . GT::Conf::get("DB::module"));
my $indicator_name = $indicator->get_name;
my $q = $db->get_prices($code);
my $calc = GT::Calculator->new($q);

$calc->set_code($code);
my $last = $q->count() - 1;
my $first = $last - 200;

$first = 0 if ($full);
$first = $last if ($last_record);
$first = 0 if ($first < 0);

if ($start) {
    my $date = $calc->prices->find_nearest_following_date($start);
    $first = $calc->prices->date($date);
}
if ($end) {
    my $date = $calc->prices->find_nearest_preceding_date($end);
    $last = $calc->prices->date($date);
}


# Au boulot
print "Calculating indicator $indicator_name ...\n";
$indicator->calculate_interval($calc, $first, $last);

for(my $i = $first; $i <= $last; $i++)
{
    for(my $n = 0; $n < $indicator->get_nb_values; $n++)
    {
	my $name = $indicator->get_name($n);
	
	if ($calc->indicators->is_available($name, $i)) {
	    my $value = $calc->indicators->get($name, $i);
	    if ($value =~ /^\d+(?:\.\d+)?$/) {
		printf "%-20s[%s] = %.4f\n", $name, $q->at($i)->[$DATE], $value;
	    } else {
		printf "%-20s[%s] = %s\n", $name, $q->at($i)->[$DATE], $value;
	    }
		    
	}
    }
}

$db->disconnect;

