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

=item --full

Display signal results using all available data. By default, the script will only display the last 200 periods.

=item --timeframe=tick|1min|5min|10min|15min|30min|hour|2hour|3hour|4hour|day|week|month|year

timeframe can be any of the available modules in GT/DateTime.

=item --start <date1> --end  <date2>

The time interval to run the evaluation on (no defaults, see --full)

=item --change ( or -c )

show on output only those dates that signal changed

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
my ($full, $start, $end, $tf)
 = (0,     '',     '',   'day');

my ($change)
 = (0); # option to show only signal changes

Getopt::Long::Configure('require_order');
GetOptions('full!' => \$full, 'timeframe=s' => \$tf,
	   'start=s' => \$start, 'end=s' => \$end,
           "change!" => \$change,
          );
my $timeframe = GT::DateTime::name_to_timeframe($tf);
if (!defined($timeframe)) {
	my $msg = "Unkown timeframe: $tf\nAvailable timeframes are:\n";
	foreach (GT::DateTime::list_of_timeframe()) {
		$msg .= '\t'.GT::DateTime::name_of_timeframe($_) . '\n';
	}
	die($msg);
}

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

# Create the complete framework
my $db = create_standard_object('DB::' . GT::Conf::get('DB::module'));
my $signal_name = $signal->get_name;
my ($q, $calc) = get_timeframe_data($code, $timeframe, $db);
my $last = $q->count() - 1;
my $first = $last - 200;

$first = 0 if ($full);
$first = 0 if ($first < 0);

# very rudimentary date format check
my $dash_count;

if ($start) {
    $_ = $start;
    print STDERR "\nthe only date format that i like is YYYY-MM-DD,\n"
               . "i don't think --start=$start is going to do what you expect\n"
      if ( ( $dash_count = $_ =~ tr/-//d ) != 2 );
    my $date = $calc->prices->find_nearest_following_date($start);
    $first = $calc->prices->date($date);
}
if ($end) {
    $_ = $end;
    print STDERR "\nthe only date format that i like is YYYY-MM-DD,\n"
               . "i don't think --end=$end is going to do what you expect\n"
      if ( ( $dash_count = $_ =~ tr/-//d ) != 2 );
    my $date = $calc->prices->find_nearest_preceding_date($end);
    $last = $calc->prices->date($date);
}

#print STDERR "first $first, last $last\n";
#exit;
print "\t$signal_module\n";
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
            printf "%-20s[%s] = %s\n", $name, $q->at($i)->[$DATE],
                    ($calc->signals->get($name, $i) ? 'yes' : 'no');
          }else{
            # show only changes from prior
            my $state = $calc->signals->get($name, $i);

            if ( ! defined ( $prior_state ) ) {
              printf "%-20s[%s] = %s\n", $name, $q->at($i)->[$DATE],
               ($state ? 'yes' : 'no');
            } else {
              if ( $prior_state != $state ) {
                printf "%-20s[%s] = %s\n", $name, $q->at($i)->[$DATE],
                 ($state ? 'yes' : 'no');
              }
            }
            $prior_state = $state;
          }
        }
    }
}

$db->disconnect;
