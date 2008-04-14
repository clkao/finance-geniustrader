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

use Date::Calc qw( Date_to_Days );
#use Date::Manip;

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
GetOptions('full!' => \$full, 'nb-item=i' => \$nb_item, 
	   "start=s" => \$start, "end=s" => \$end, 
	   "max-loaded-items" => \$max_loaded_items,
	   "timeframe=s" => \$timeframe,
            'verbose+'		=> \$verbose,
            'nbprocess=s'	=> \$nbprocess,
            "html!"		=> \$html,
            "url=s"		=> \$url,
           );

# Create all the framework
my $list = GT::List->new;

# get symbols filename from command line
my $file = shift || pod2usage(verbose => 2);
$list->load($file);    # checking done in sub $list->load

# get date string from command line
my $date = shift;

# date check introduced by ras
# comment out if not desired
($date, $start, $end) = check_date($timeframe, $date, $start, $end);


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

$timeframe = GT::DateTime::name_to_timeframe($timeframe);

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

sub check_date {
  my ($timeframe, $date, $start, $end) = @_;

  # assumptions: date is the day of interest
  #              start and end dates define time span under analysis
  #              date is expected to be within that time span
  #              timeframe is the time period chunk size
  #              start and end dates must match the selected timeframe
  #
  #
  # datetime formats permitted
  # yyyy-mm-dd with or without leading zeros
  # yyyymmdd with required leading zeros
  # <date> hh:mm:ss with required separator and leading zeros
  if ( ! $date ) {
    print STDERR "$prog_name: error: require date parameter\n\n";
    print STDERR "date formats are YYYY-MM-DD with or without leading zeros\n";
    print STDERR "                 YYYYMMDD leading zeros required\n\n";
    print STDERR "time formats for sub day timeframes is:\n";
    print STDERR "                 <date> HH:MM:SS\n\n";
    print STDERR "explicit timeframe required if time included in date\n\n";
    usage();
    exit 1;
  }

  my $tf;
  my $time;
  my $err_msg;

  my $in_date = $date;
  my $in_start = $start if ( $start );
  my $in_end = $end if ( $end );

  if ( $timeframe ) {
    $tf = GT::DateTime::name_to_timeframe($timeframe);
  } else {
    # assume default is $DAY timeframe
    $tf = $DAY;
  }

  my ( $d_yr, $d_mn, $d_dy, $d_tm );
  if ( ! parse_date_str( \$date, \$err_msg ) ) {
    die "$prog_name: error: $err_msg\n";
  } else {
    ( $d_yr, $d_mn, $d_dy, $d_tm ) = split /[- ]/, $date;
  }

  my ( $s_yr, $s_mn, $s_dy, $s_tm );
  if ( $start ) {
    if ( ! parse_date_str( \$start, \$err_msg ) ) {
      die "$prog_name: error: \$err_msg\n";
    } else {
      ( $s_yr, $s_mn, $s_dy, $s_tm ) = split /[- ]/, $start;
    }
  }

  my ( $e_yr, $e_mn, $e_dy, $e_tm );
  if ( $end ) {
    if ( ! parse_date_str( \$end, \$err_msg ) ) {
      die "$prog_name: error: \$err_msg\n";
    } else {
      ( $e_yr, $e_mn, $e_dy, $e_tm ) = split /[- ]/, $end;
    }
  }

  if ( $start && $end ) {
    # $start must be prior to $end
    if (Date_to_Days($s_yr, $s_mn, $s_dy) >=
	Date_to_Days($e_yr, $e_mn, $e_dy)) {
      warn "$prog_name: --start date must be prior to --end date ($start before $end)\n";
    }
  }
  
  if ( $date && $end ) {
    # $date must be $end or before
    if (Date_to_Days($d_yr, $d_mn, $d_dy) >
	Date_to_Days($e_yr, $e_mn, $e_dy)) {
      warn "$prog_name: date must be prior to or equal --end date ($date before $end)\n";
    }
  }
  
  if ( $date && $start ) {
    # $start must be prior to $date
    if (Date_to_Days($s_yr, $s_mn, $s_dy) >=
	Date_to_Days($d_yr, $d_mn, $d_dy)) {
      warn "$prog_name: --start must be prior to date ($start before $date)\n";
    }
  }

  # this is really debug code
  if ( $verbose ) {
    print STDERR "\npre timeframe adjust:\n";
    print STDERR "date:\t$date\n";
    print STDERR "start:\t$start\n";
    print STDERR "end:\t$end\n";
  }

  # timeframe relative date conversions
  if ( $start && $tf != $DAY ) {
    $start = GT::DateTime::convert_date($start, $DAY, $tf);
  }

  if ( $end && $tf != $DAY ) {
    $end = GT::DateTime::convert_date($end, $DAY, $tf);
  }

  if ( $tf != $DAY && $tf > $DAY ) {
    $date = GT::DateTime::convert_date($date, $DAY, $tf);
  }

  # this is really debug code
  if ( $verbose ) {
    print STDERR "\npost timeframe adjust:\n";
    print STDERR "date:\t$date\n";
    print STDERR "start:\t$start\n";
    print STDERR "end:\t$end\n\n";
  }

  return ($date, $start, $end);

}


sub usage {
  print STDERR "$prog_name [ options ] symbols_file date spec_file [ spec_file ... ]\n";
  print STDERR "\n";
  print STDERR "where symbols_file is a file containing one symbol code per line\n";
  print STDERR "      standard date format is YYYY-MM-DD\n";
  print STDERR "      spec_file is a file containing one or more\n";
  print STDERR "      system or signal specifications\n";
  print STDERR "\n";
  print STDERR "      multiple specification files will be read or stdin if not supplied\n";
  print STDERR "\n";
  print STDERR "      date can include optional time: <date>' HH:MM:SS'\n";
  if ( eval { require Date::Manip } ) {
    print STDERR "\n  ah! since you have Date::Manip available date strings can also be specified\n";
    print STDERR "  in any format that Date::Manip can parse. common useful strings include:\n";
    print STDERR "  'today', 'yesterday', 'last friday', '6 months ago', '1st of last month'\n";
    print STDERR "  are all simple examples that make date entry much more human-date relative\n";
    print STDERR "  \"perldoc -t Date::Manip\" for the gory details on date string parsing\n";
  }  
  print STDERR "\n";
  print STDERR "for the full story on $prog_name try \"perldoc -t $prog_name\" for more details\n";
  print STDERR "\n";
}


=pod

=head2 this is a ras hack version of scan.pl that includes date string checks

 if the user has Date::Manip installed it allows the use of date strings
 that can be parsed by Date::Manip in addition the to defacto standard
 date-time format accepted by GT (YYYY-MM-DD HH:MM:SS) time part is optional

 Date::Manip is not required, without it users cannot use short-cuts to
 specify date strings. such short cuts include
 --start '6 months ago'
 --end 'today'

 the date string checking includes verifying the date string format
 is valid and the date is a valid date (and time if provided)

 errors will be displayed and the script will terminate.

 the script also validates that the dates specified are consistent
 with respect to their purpose (--start is earlier than --end etc)

 finally, appropriate timeframe conversion is performed so the user
 need not convert command line date strings from the day time to
 say week or month as it will be done automagically.

 usage examples:

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

=cut

