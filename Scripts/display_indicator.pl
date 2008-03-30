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

=item --full 

Runs the backtest on the full history (it runs on two years by default) 

=item --nb-items=100

nb-items controls how many database records are loaded.

=item --timeframe=1min|5min|10min|15min|30min|hour|3hour|Day|Week|Month|Year

The timeframe can be any of the available modules in GT/DateTime.  

=item --last-record

Run backtest on the last period only.

=back

=head2 Examples

./display_indicator.pl I:SMA IBM 100

./display_indicator.pl --full I:RSI 13000

args (if any) are passed to the new call that will create the indicator.

./display_indicator.pl --nb 10 I:EMA IBM 120

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
my $indicator_name = $indicator->get_name;
my ($calc, $first, $last) = ($last_record) ?
  find_calculator($code, $timeframe, 0, '', '', 1, $nb_item) :
  find_calculator($code, $timeframe, $full, $start, $end, 200, $nb_item);


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

