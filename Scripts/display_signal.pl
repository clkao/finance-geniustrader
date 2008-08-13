#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# baseline Mar 17 2006 2293 bytes
# $Id$

use lib '..';

use strict;
use vars qw($db);

use GT::Prices;
use GT::Calculator;
use GT::Conf;
use GT::Eval;
use Getopt::Long;
use GT::Tools qw(:timeframe);
use Pod::Usage;

GT::Conf::load();

=head1 ./display_signal.pl [ options ] <signalname> <code> [args...]

=head2 Description

Computes the value of signal <signalname> for market <code> over
the selected interval.

=head2 Options

=over 4

=item --full, --start=<date>, --end=<date>, --nb-item=<nr>

Determines the time interval to consider for analysis. In detail:

=over

=item --start=2001-1-10, --end=2002-11-17

The start and end dates considered for analysis. The date needs to be in the
format configured in ~/.gt/options and must match the timeframe selected. 

=item --nb-items=100

The number of periods to use in the analysis. Default is 200.

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

=item --change ( or -c )

show on output only those dates that signal changed

=item --options=<key>=<value>

A configuration option (typically given in the options file) in the
form of a key=value pair. For example,
 --option=DB::Text::format=0
sets the format used to parse markets via the DB::Text module to 0.

=back

=head2 Arguments

=over 4

=item <signalname>

The name of the signal you want to display. This can be any module under GT/Signals.
For instance, S::Generic::CrossOverUp.

=item <code>

The symbol for which you wish to display the signal.
Use whatever symbols are available in your database.

=item [args...]

Args are passed to the new call that will create the signal.
args is a string that specifies the signal in gt terms, spaces and other
chars that the shell interprets will need to be quoted in some way.

=back

=head2 Examples

./display_signal.pl S:Prices:GapUp IBM

Test for the GapUp signal in symbol IBM.
By default, use daily data, and display the last available 200 periods.


./display_signal.pl --full S:Generic:CrossOverUp EURUSD {I:EMA 50} {I:EMA 200}

Test for the EMA50 crossing over up EMA200.
Do the test over the full available history data.

=cut

# Get all options
my ($change, $last_record)
 = (0, 0);
my $nb_item = GT::Conf::get('Option::nb-item');
$nb_item = (defined($nb_item))?$nb_item:200;
my ($full, $start, $end, $timeframe, $max_loaded_items) =
   (0, '', '', 'day', -1);
my $man = 0;
my @options;
Getopt::Long::Configure('require_order');
GetOptions('full!' => \$full, 'nb-item=i' => \$nb_item, 
	   "start=s" => \$start, "end=s" => \$end, 
	   "max-loaded-items=s" => \$max_loaded_items,
	   "timeframe=s" => \$timeframe,
           "change!" => \$change, "last-record" => \$last_record,
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

# Verify dates and adjust to timeframe, comment out if not desired
check_dates($timeframe, $start, $end);

# Create the signal according to the arguments
my $signal_module = shift || pod2usage(verbose => 1);
my $code = shift || pod2usage(verbose => 1);

if ( $code =~ /{|}|:/ ) {
  print STDERR "$0: warning: humm i read stock code as \"$code\"\n";
  print STDERR "that looks a bit like signal description text to me\n";
  print STDERR "\ncommand line order is\n$0 <signal_module_name> <code> <signal_description>\n\n";
  print STDERR "$0 [ options ] <signal_module_name> <code> <signal_description_text>\n\n";
}

my $signal = create_standard_object($signal_module, @ARGV);
my $signal_name = $signal->get_name;

my $db = create_db_object();

my ($calc, $first, $last) = find_calculator($db, $code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);

# Launching the signal
print "Testing signal $signal_name ...\n";
$signal->detect_interval($calc, $first, $last);

my $prior_state = undef;
for(my $i = $first; $i <= $last; $i++)
{
    for(my $n = 0; $n < $signal->get_nb_values; $n++)
    {
        my $name = $signal->get_name($n);

        if ($calc->signals->is_available($name, $i)) {
          if ( ! $change ) {
            printf "%-20s[%s] = %s\n", $name, $calc->prices->at($i)->[$DATE],
                    ($calc->signals->get($name, $i) ? 'yes' : 'no');
          }else{
            # show only changes from prior
            my $state = $calc->signals->get($name, $i);

            if ( ! defined ( $prior_state ) ) {
              printf "%-20s[%s] = %s\n", $name, $calc->prices->at($i)->[$DATE],
               ($state ? 'yes' : 'no');
            } else {
              if ( $prior_state != $state ) {
                printf "%-20s[%s] = %s\n", $name, $calc->prices->at($i)->[$DATE],
                 ($state ? 'yes' : 'no');
              }
            }
            $prior_state = $state;
          }
        }
    }
}

$db->disconnect;

