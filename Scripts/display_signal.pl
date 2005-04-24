#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;
use vars qw($db);

use Carp::Datum (":all", defined($ENV{'GTDEBUG'}) ? "on" : "off");
use GT::Prices;
use GT::Calculator;
use GT::Report;
use GT::Conf;
use GT::Eval;
use Getopt::Long;

GT::Conf::load();

=head1 ./test_signals.pl [ --full ] [ --verbose ] <signalname> <code> [args...]

Examples:
./test_signals.pl S:Prices:GapUp IBM
./test_signals.pl --full S:I:RSIUp 13000 18

Args are passed to the new call that will create the signal.

=cut

# Get all options
my ($full, $verbose, $start, $end) = (0, 0, '', '');
Getopt::Long::Configure("require_order");
GetOptions('full!' => \$full, "verbose" => \$verbose,
	   "start=s" => \$start, "end=s" => \$end);

# Create the signal according to the arguments
my $signal_module = shift;
my $code = shift;

my $signal = create_standard_object("$signal_module", @ARGV);

# Create the complete framework
my $db = create_standard_object("DB::" . GT::Conf::get("DB::module"));
my $signal_name = $signal->get_name;
my $q = $db->get_prices($code);
my $calc = GT::Calculator->new($q);

$calc->set_code($code);
my $last = $q->count() - 1;
my $first = $last - 200;

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


# Launching the signal
print "Testing signal $signal_name ...\n";
$signal->detect_interval($calc, $first, $last);

for(my $i = $first; $i <= $last; $i++)
{
    for(my $n = 0; $n < $signal->get_nb_values; $n++)
    {
        my $name = $signal->get_name($n);
        
        if ($calc->signals->is_available($name, $i)) {
            printf "%-20s[%s] = %s\n", $name, $q->at($i)->[$DATE], 
                    ($calc->signals->get($name, $i) ? "yes" : "no");
        }
    }
}

$db->disconnect;

