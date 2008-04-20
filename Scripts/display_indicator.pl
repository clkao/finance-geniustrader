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

=head1 ./display_indicator.pl [ options ] <indicatorname> <code> [args...]

=head2 Description

Computes the indicator <indicatorname> on market <code> over the selected
interval.

=head2 Options

=over 4

=item --full, --start=<date>, --end=<date>, --nb-item=<nr>

Determines the time interval to consider for analysis. In detail:

=over

=item --start=2001-1-10, --end=2002-11-17

The start and end dates considered for analysis. The date needs to be in the
format configured in ~/.gt/options and must match the timeframe selected. 

=item --nb-items=100

The number of periods to use in the analysis.

=item --full

Consider all available periods.

=back

The periods considered are relative to the selected time frame (i.e., if timeframe
is "day", these indicate a date; if timeframe is "week", these indicate a week;
etc.). In GT format, use "YYYY-MM-DD" or "YYYY-MM-DD hh:mm:ss" for days (the
latter giving intraday data), "YYYY-WW" for weeks, "YYYY/MM" for months, and 
"YYYY" for years.

The interval of periods examined is determined as follows:

=over

=item 1 if present, use --start and --end (otherwise default to last price)

=item 1 use --nb-item (from first or last, whichever has been determined), 
if present

=item 1 if --full is present, use first or last price, whichever has not yet been determined

=item 1 otherwise, consider a two year interval.

=back

The first period determined following this procedure is chosen. If additional
options are given, these are ignored (e.g., if --start, --end, --full are given,
--full is ignored).

=item --timeframe=1min|5min|10min|15min|30min|hour|3hour|day|week|month|year

The timeframe can be any of the available modules in GT/DateTime.  

=item --last-record

Display results for the last period only. Overrides any other options given
to determine the interval.

=item --max-loaded-items

Determines the number of periods (back from the last period) that are loaded
for a given market from the data base. Care should be taken to ensure that
these are consistent with the performed analysis. If not enough data is
loaded to satisfy dependencies, for example, correct results cannot be obtained.
This option is effective only for certain data base modules and ignored otherwise.

=item --options=<key>=<value>

A configuration option (typically given in the options file) in the
form of a key=value pair. For example,
 --option=DB::Text::format=0
sets the format used to parse markets via the DB::Text module to 0.

=back

=head2 Examples

./display_indicator.pl I:SMA IBM 100

./display_indicator.pl --full I:RSI 13000

args (if any) are passed to the new call that will create the indicator.

./display_indicator.pl --nb 10 I:EMA IBM 120

=cut

# Get all options
my ($full, $nb_item, $start, $end, $timeframe, $max_loaded_items) =
   (0, 0, '', '', 'day', -1);
my $man = 0;
my @options;
my $last_record = 0;
Getopt::Long::Configure("require_order");
GetOptions('full!' => \$full, 'nb-item=i' => \$nb_item, 
	   "start=s" => \$start, "end=s" => \$end, 
	   "max-loaded-items" => \$max_loaded_items,
	   "timeframe=s" => \$timeframe,
	   "last-record" => \$last_record,
	   "option=s" => \@options, "help!" => \$man);
$timeframe = GT::DateTime::name_to_timeframe($timeframe);

foreach (@options) {
    my ($key, $value) = split (/=/, $_);
    GT::Conf::set($key, $value);
}

pod2usage( -verbose => 2) if ($man);

if ($last_record) {
  $full = 0;
  $start = '';
  $end = '';
  $nb_item = 1;
}
# Create the indicator according to the arguments
my $indicator_module = shift || pod2usage(verbose => 2);
my $code = shift || pod2usage(verbose => 2);

my $indicator = create_standard_object("$indicator_module",
					@ARGV);

# Il faut créer tout le framework
my $indicator_name = $indicator->get_name;
my ($calc, $first, $last) = find_calculator($code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);


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
		printf "%-20s[%s] = %.4f\n", $name, $calc->prices->at($i)->[$DATE], $value;
	    } else {
		printf "%-20s[%s] = %s\n", $name, $calc->prices->at($i)->[$DATE], $value;
	    }
		    
	}
    }
}

