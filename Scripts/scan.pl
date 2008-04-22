#!/usr/bin/perl -w

# Copyright 2000-2003 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# base version 22 May 2005 bytes 6478
# $Id$

use lib '..';

use strict;
use vars qw($db);

use GT::Prices;
use GT::Calculator;
use GT::List;
use GT::Eval;
use GT::Conf;
use GT::Tools qw(:conf :generic :timeframe);
use GT::DateTime;
use IPC::SysV qw(IPC_PRIVATE S_IRWXU IPC_NOWAIT);
use IPC::Msg;
use Getopt::Long;
use Pod::Usage;

GT::Conf::load();

( my $prog_name = $0 ) =~ s@^.*/@@;    # lets identify ourself

=pod

=head1 NAME

scan.pl - scan the market looking for signals

=head1 SYNOPSIS

./scan.pl [ options ] <market file> <date> <system file> [ <system file> ... ]

=head1 DESCRIPTION

scan.pl will scan all stocks listed in <market file> looking
for the signals indicated in each <system file> performing the analysis
on the specified <date>. A system file must contain one or more description
of GT::Signals or description of GT::Systems. You may list multiple system
files on the command line. In the absence of a file standard input will
be read instead.

NOTE -- if you omit a system file name scan.pl will happily wait forever
attempting to read from stdin.

The list of securities (code and name) that meet the specified signals
is output at the end and grouped by signal.

Output can be either text (default) or html.

<market file> format:

=over 4

stock or index symbols one per line

=back

<date>

the date to perform the analysis on. the date string can be in any format
that Date::Manip (if installed) can parse or the defacto gt standard date
format (YYYY-MM-DD HH:MM:SS) where time is optional

<system file> format:

=over 4

One or more GT::Signals or GT::Systems descriptions each on a separate line.
The descriptions have the form of a signal or system name, followed by its
arguments.

Example:
     S:Generic:And {S:Generic:CrossOverUp {I:SMA 5} {I:SMA 20}} {S:Generic:Increase {I:ADX}}


Description files can be formatted using the symbol '\' as the
line continuation symbol. This symbol must appear as the last character
on the line before the trailing line terminator (in unix that's
a '\n' character). No whitespace must appear between the \ and the newline.

Example:
     S:Generic:And \
       {S:Generic:CrossOverUp {I:SMA 5} {I:SMA 20}} \
       {S:Generic:Increase {I:ADX}}

Blank lines and lines that start with # are comments and ignored.
Note if you comment out the first line of multi-line description,
the entire is effectively commented out.

Example:
     # the following signal description is commented out
     #S:Generic:And {S:Generic:Above {I:Prices} {I:EMA 30}} \
      {S:Generic:Above {I:Prices} {I:EMA 150}}

=back

=head1 OPTIONS

=over 4

=item --full, --start=<date>, --end=<date>, --nb-item=<nr>

Determines the time interval over which the scan is run. In detail:

=over

=item --start=2001-1-10, --end=2002-11-17

The start and end dates considered for the scan. The date needs to be in the
format configured in ~/.gt/options and must match the timeframe selected. 

=item --nb-items=100

The number of periods to use in the scan.

=item --full

Runs the scan with the full history.

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

=item --max-loaded-items

Determines the number of periods (back from the last period) that are loaded
for a given market from the data base. Care should be taken to ensure that
these are consistent with the performed analysis. If not enough data is
loaded to satisfy dependencies, for example, correct results cannot be obtained.
This option is effective only for certain data base modules and ignored otherwise.

=item --verbose

Makes scan.pl and invoked methods talkative (default - false)

=item --nbprocess=2

If you want to start two (or more) scans in parallel (useful for machines with several CPUs for example).

=item --html

Output is generated in html (default - false)

=item --url="url"

If html output enabled then embed this url as href (default - http://finance.yahoo.com/l?s=<code>)

=item --options=<key>=<value>

A configuration option (typically given in the options file) in the
form of a key=value pair. For example,
 --option=DB::Text::format=0
sets the format used to parse markets via the DB::Text module to 0.

=back

=head1 EXAMPLES (culled from devel archive)

To scan for all stocks that are trading above both their 30 day and 150 day EMAs
create a system file containing this GT::Signals description (as a single line)

S:Generic:And {S:Generic:Above {I:Prices} {I:EMA 30}} {S:Generic:Above {I:Prices} {I:EMA 150}}

To scan for all stocks that are trading below both their 30 day and 150 day EMAs
create a system file containing this GT::Signals description (as a single line)

S:Generic:And {S:Generic:Below {I:Prices} {I:EMA 30}} {S:Generic:Below {I:Prices} {I:EMA 150}}

=cut

# Manage options
my ($full, $nb_item, $start, $end, $timeframe, $max_loaded_items) =
   (0, 0, '', '', 'day', -1);
my ($verbose, $nbprocess, $html, $url) = 
   (0,        1,          0,     'http://finance.yahoo.com/l?s=%s');
my $man = 0;
my @options;
GetOptions('full!' => \$full, 'nb-item=i' => \$nb_item, 
	   "start=s" => \$start, "end=s" => \$end, 
	   "max-loaded-items" => \$max_loaded_items,
	   "timeframe=s" => \$timeframe,
            'verbose+'		=> \$verbose,
            'nbprocess=s'	=> \$nbprocess,
            "html!"		=> \$html,
            "url=s"		=> \$url,
	   "option=s" => \@options, "help!" => \$man);
$timeframe = GT::DateTime::name_to_timeframe($timeframe);

foreach (@options) {
    my ($key, $value) = split (/=/, $_);
    GT::Conf::set($key, $value);
}

pod2usage( -verbose => 2) if ($man);

# Create all the framework
my $list = GT::List->new;

# get symbols filename from command line
my $file = shift || pod2usage(verbose => 2);
$list->load($file);    # checking done in sub $list->load

# get date string from command line
my $date = shift;

# Verify dates and adjust to timeframe, comment out if not desired
check_dates($timeframe, $start, $end, $date);

# Build the list of systems to test
# <> is last command line parameter -- filename of systems or signals
# reads the entire file into the desc_systems array

# read either the remaining file names on command line
# or if none read stdin
my @desc_systems = <>;
# note -- i would like to do something like "|| die" above but that
#         prevents perl from reading the entire file into array all at once
#         plus reading all the filenames on command line including stdin
my @list_systems = ();
my $systems = {};
my $buf = '';
foreach my $line (@desc_systems) {

    chomp($line);

    # ras hack -- allow multi-line values in desc_systems files
    if ( $line =~ /\\$/ ) {
      $line =~ s/\\$//;     # remove \
      $buf .= $line;        # save line
      next;                 # get next line
    } else {
      $line = $buf . $line; # collect complete line into $line
      $buf = '';            # reset line buffer
    }

    next if ($line =~ /^#|^\s+#|^$/);

    # squeeze out extra spaces
    $line =~ tr/[ \t]/[ \t]/s;     # squeeze out multiple adjacent whitespaces

    # divide line into two pieces first word and rest of line
    if ($line =~ /^\s*(\S+)\s*(.*)$/) {

	my $object = create_standard_object($1, $2);
	my $number = extract_object_number($1);
	my $name = get_standard_name($object);
	
	push @list_systems, $name;
	
	$systems->{$name}{"object"} = $object;
	$systems->{$name}{"number"} = $number;

        warn "$prog_name doesn't deal with indicators, just systems and signals\n"
         . "\"$object\" is an indicator, and will be ignored $!\n"
         if ( ref($object) =~ /GT::Indicators::/ );

	if (ref($object) =~ /GT::Systems/) {
	    $systems->{$name}{"buy_signals"} = [];
	    $systems->{$name}{"sell_signals"} = [];
	} else {
	    $systems->{$name}{"signals"} = [];
	}
    }
}

# Create the MsqQueue to collect the results
my $msg = IPC::Msg->new(IPC_PRIVATE, S_IRWXU);

sub process_msg {
    while (1) {
	my $data;
	my $res = $msg->rcv($data, 256, 1, IPC_NOWAIT);
	if (defined($res) && $res) {
	    my ($code, $index, $signal) = ($data =~ /^(\S+) (\d+) (\w)$/);
	    my $name = $list_systems[$index];
	    if ($signal eq "A") {
		push @{$systems->{$name}{"signals"}}, $code;
	    } elsif ($signal eq "B") {
		push @{$systems->{$name}{"buy_signals"}}, $code;
	    } elsif ($signal eq "S") {
		push @{$systems->{$name}{"sell_signals"}}, $code;
	    }
	} else {
	    last;
	}
    }
}

# Actually launch the backtests
my $analysis;
my $count_process = 0;
for (my $d = 0; $d < $list->count; $d++)
{
    if (fork())
    {
	$count_process++;
	next if ($count_process < $nbprocess);
	wait;
	&process_msg();
	$count_process--;
	next;
    }
    my $code = $list->get($d);

    my ($calc, $first, $last) = find_calculator($code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);

    my $i;
    if ($calc->prices->has_date($date)) {
	$i = $calc->prices->date($date);
    } else {
	my $ndate = $calc->prices->find_nearest_preceding_date($date);
	$i = $calc->prices->date($ndate);
    }

    # do the analyses
    my $n = 0;
    foreach (@list_systems)
    {

        print STDERR "working " . $calc->code . " " if ($verbose >= 1);
    
	my $object = $systems->{$_}{'object'};
	my $number = $systems->{$_}{'number'};
	if (ref($object) =~ /GT::Systems/) {
	    if ($object->long_signal($calc, $i)) {
		$msg->snd(1, "$code $n B");
	    }
	    if ($object->short_signal($calc, $i)) {
		$msg->snd(1, "$code $n S");
	    }
	} elsif (ref($object) =~ /GT::Signals/) {
	    $object->detect($calc, $i);
	    if ($calc->signals->is_available($object->get_name($number), $i)
		&& $calc->signals->get($object->get_name($number), $i)) {
		$msg->snd(1, "$code $n A");
	    }
	}
	$n++;

        print STDERR "spec $n\n" if ($verbose >= 1);

    }

    # Close the child 
    exit 0;
}

# Wait last processes
while ($count_process > 0) {
    wait;
    &process_msg();
    $count_process--;
}
$msg->remove;


# Display results
my $db = create_db_object();
foreach my $name (@list_systems) {
    my $object = $systems->{$name}{'object'};
    if (ref($object) =~ /GT::Systems/) {
	print "<p>" if ($html);
	print "\nBuy signal: $name\n";
	print "</p>" if ($html);
	print "<ul>" if ($html);
#      {
#        no warnings qw(numeric);
#	foreach my $code (sort { $a <=> $b || $a cmp $b } @{$systems->{$name}{'buy_signals'}}) {
	foreach my $code (sort scan_sort_sub @{$systems->{$name}{'buy_signals'}}) {
	    display_item($db, $code, $html, $url);
	}
#      }
	print "</ul>" if ($html);
	print "<p>" if ($html);
	print "\nSell signal: $name\n";
	print "</p>" if ($html);
	print "<ul>" if ($html);
#      {
#        no warnings qw(numeric);
#	foreach my $code (sort { $a <=> $b || $a cmp $b } @{$systems->{$name}{'sell_signals'}}) {
	foreach my $code (sort scan_sort_sub @{$systems->{$name}{'sell_signals'}}) {
	    display_item($db, $code, $html, $url);
	}
#      }
	print "</ul>" if ($html);
    } elsif (ref($object) =~ /GT::Signals/) {
	print "<p>" if ($html);
	print "\nSignal: $name\n";
	print "</p>" if ($html);
	print "<ul>" if ($html);
       foreach my $code (sort scan_sort_sub @{$systems->{$name}{'signals'}}) {
           display_item($db, $code, $html, $url);
       }
#      {
#        no warnings qw(numeric);
#	foreach my $code (sort { $a <=> $b || $a cmp $b } @{$systems->{$name}{'signals'}}) {
#	    display_item($db, $code, $html, $url);
#	}
#      }
	print "</ul>" if ($html);
    }
}
$db->disconnect;


sub scan_sort_sub {
  no warnings qw(numeric);
  $a <=> $b
      ||
  $a cmp $b
}


sub display_item {
    my ($db, $code, $html, $url) = @_;
    my $name = $db->get_name($code);
    if ($html) {
	my $real_url = $url;
	$real_url =~ s/\%s/$code/;
	print "<li><a href='$real_url'>";
	if ($name) {
	    print "$name</a> ($code)";
	} else {
	    print "$code</a>";
	}
	print "</li>\n";
    } else {
	print " $code\t $name\n";
    }
}

=pod

=head2 Dates

 If the user has Date::Manip installed it allows the use of date strings
 that can be parsed by Date::Manip in addition the to defacto standard
 date-time format accepted by GT (YYYY-MM-DD HH:MM:SS) time part is optional

 Date::Manip is not required, without it users cannot use short-cuts to
 specify date strings. such short cuts include
 --start '6 months ago'
 --end 'today'

 Date string checking includes verifying the date string format
 is valid and the date is a valid date (and time if provided)

 Errors will be displayed and the script will terminate.

 The script also validates that the dates specified are consistent
 with respect to their purpose (--start is earlier than --end etc)

 Finally, appropriate timeframe conversion is performed so the user
 need not convert command line date strings from the day time to
 say week or month as it will be done automagically.

 Usage examples:

 with market_file (a file) containing the next 2 lines:
 JAVA
 AAPL

 with system_file (a file) containing the next 6 lines:
 # example system_file
 #
 # todays price close was above open
 
 S:Generic:Above { I:Prices CLOSE } { I:Prices OPEN }
 # end of system_file

 with Date::Manip installed
 %    scan.pl --timeframe day --start '6 months ago' --end 'today' market_file \
  'today' system_file
 prints

 Signal: S:Generic:Above {I:Prices CLOSE} {I:Prices OPEN}
  AAPL - APPLE INC

 replace day with week and you will (should) get:

 Signal: S:Generic:Above {I:Prices CLOSE} {I:Prices OPEN}
  AAPL - APPLE INC
  JAVA - SUN MICROSYS INC


 without Date::Manip you will need to use:
 %    scan.pl --timeframe day --start 2007-04-24 --end 2007-10-24 market_file \
  2007-10-24 system_file
 or
 %    scan.pl --timeframe week --start 2007-04-24 --end 2007-10-24 market_file \
  2007-10-24 system_file
 and should get the same results respectively

=head2 "Bad system call" failure on cygwin

If you are using cygwin on Windows to run GT, and you encounter
a "Bad system call" error when running scan.pl, you need to enable
cygserver. cygserver is a utility that provides cygwin applications
with persistent services. See 
  http://www.cygwin.com/cygwin-ug-net/using-cygserver.html
for more detail. The first time you use cygserver, execute
  /usr/bin/cygserver-config
to configure the service (there are many options but the above should
suffice, see the manual for more). You can then invoke the service
automatically through windows, or use
  net start cygserver
to do so. You must also set the CYGWIN environment variable to 'server':
  CYGWIN=server
  export CYGWIN

=cut

