#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

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

=head1 NAME

display_signal.pl

=head1 SYNOPSIS

./display_signal.pl [ --full ] [ --timeframe=timeframe ] <signalname> <code> [args...]

=head1 DESCRIPTION

Display the results of any given signal over a period of time. Mostly usefull for development purposes.

=head1 OPTIONS

=head2 --full

Display signal results using all available data. By default, the script will only display the last 200 periods.

=head2 --timeframe

The timeframe used to plot the graphic. Defaults to daily data.
Valid values include:
tick|1min|5min|10min|15min|30min|hour|2hour|3hour|4hour|day|week|month|year

=head2 <signalname>

The name of the signal you want to display. This can be any module under GT/Signals.
For instance, S::Generic::CrossOverUp.

=head2 <code>

The symbol for which you wish to display the signal.
Use whatever symbols are available in your database.

=head2 [args...]

Args are passed to the new call that will create the signal.

=head1 EXAMPLES

=head2 ./display_signal.pl S:Prices:GapUp IBM

Test for the GapUp signal in symbol IBM.
By default, use daily data, and display the last available 200 periods.


=head2 ./display_signal.pl --full S:Generic:CrossOverUp EURUSD {I:EMA 50} {I:EMA 200}

Test for the EMA50 crossing over up EMA200.
Do the test over the full available history data.

=cut

# Get all options
my ($full, $start, $end, $tf) = (0, '', '', 'day');
Getopt::Long::Configure('require_order');
GetOptions('full!' => \$full, 'timeframe=s' => \$tf,
	   'start=s' => \$start, 'end=s' => \$end);
my $timeframe = GT::DateTime::name_to_timeframe($tf);
if (!defined($timeframe)) {
	my $msg = "Unkown timeframe: $tf\nAvailable timeframes are:\n";
	foreach (GT::DateTime::list_of_timeframe()) {
		$msg .= '\t'.GT::DateTime::name_of_timeframe($_) . '\n';
	}
	die($msg);
}

# Create the signal according to the arguments
my $signal_module = shift || pod2usage(verbose => 2);
my $code = shift || pod2usage(verbose => 2);

my $signal = create_standard_object($signal_module, @ARGV);

# Create the complete framework
my $db = create_standard_object('DB::' . GT::Conf::get('DB::module'));
my $signal_name = $signal->get_name;
my ($q, $calc) = get_timeframe_data($code, $timeframe, $db);
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
                    ($calc->signals->get($name, $i) ? 'yes' : 'no');
        }
    }
}

$db->disconnect;
