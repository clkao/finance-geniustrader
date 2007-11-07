#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;
use vars qw($db);

use GT::Prices;
use GT::Conf;
use GT::Eval;
use Getopt::Long;
use GT::DateTime;
use GT::Tools qw(:timeframe);
use Pod::Usage;

GT::Conf::load();

=head1 ./display_indicator.pl [ --full ] [--nb-items=100] [ --timeframe=timeframe ] [ --last-record ] <indicatorname> <code> [args...]

nb-items controls how many database records are loaded.

timeframe can be any of the available modules in GT/DateTime.  
At the time of this writing that includes:

1min|5min|10min|15min|30min|hour|3hour|Day|Week|Month|Year

Examples:

./display_indicator.pl I:SMA IBM 100

./display_indicator.pl --full I:RSI 13000

Args are passed to the new call that will create the indicator.

=cut

# Get all options
my ($full, $last_record, $start, $end, $timeframe, $nb_item) = 
    (0, 0, '', '', 'day', -1);
Getopt::Long::Configure("require_order");
GetOptions('full!' => \$full, "last-record" => \$last_record, 'nb-item=i' => \$nb_item,
	   "start=s" => \$start, "end=s" => \$end, "timeframe=s" => \$timeframe);
$timeframe = GT::DateTime::name_to_timeframe($timeframe);
# Create the indicator according to the arguments
my $indicator_module = shift || pod2usage(verbose => 2);
my $code = shift || pod2usage(verbose => 2);

my $indicator = create_standard_object("$indicator_module",
					@ARGV);

# Il faut créer tout le framework
my $db = create_standard_object("DB::" . GT::Conf::get("DB::module"));
my $indicator_name = $indicator->get_name;
my ($q, $calc) = get_timeframe_data($code, $timeframe, $db, $nb_item);

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

