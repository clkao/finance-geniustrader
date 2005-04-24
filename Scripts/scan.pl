#!/usr/bin/perl -w

# Copyright 2000-2003 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;
use vars qw($db);

use Carp::Datum (":all", defined($ENV{'GTDEBUG'}) ? "on" : "off");
use GT::Prices;
use GT::Calculator;
use GT::List;
use GT::Eval;
use GT::Conf;
use GT::Tools qw(:conf :generic);
use GT::DateTime;
use IPC::SysV qw(IPC_PRIVATE S_IRWXU IPC_NOWAIT);
use IPC::Msg;
use Getopt::Long;

GT::Conf::load();

=head1 NAME

scan.pl - scan the market looking for signals

=head1 SYNOPSIS

./scan.pl [ options ] <market file> <date> <system file>

=head1 DESCRIPTION

Scan.pl will scan all stocks listed in <market file> looking
for the signals indicated in <system file> at the given <date>. The system
file can contain description of GT::Signals or description of
GT::Systems.

The list of detected signals is ouptut at the end and grouped by signal.

=head1 PARAMETERS

=over 4

=item --full

Runs the scan with the full history (it runs with two years by default)

=item --timeframe="day|week|month|year"

Runs the scan using the given timeframe.

=item --nbprocess=2

If you want to start two (or more) scans in parallel (useful for machines with several CPUs for example).

=back

=cut

# Manage options
my ($full, $verbose, $timeframe, $start, $end, $nbprocess, $html, $url) = 
   (0, 0, '', '', '', 1, 0, 'http://finance.yahoo.com/l?s=%s');
GetOptions('full!' => \$full, 'verbose' => \$verbose, 
	   'timeframe=s' => \$timeframe, "start=s" => \$start,
	   "end=s" => \$end, 'nbprocess=s' => \$nbprocess,
	   "html!" => \$html, "url=s" => \$url);

# Create all the framework
my $list = GT::List->new;
my $file = shift;
if (! -e $file)
{
    die "File $file doesn't exist.\n";
}
$list->load($file);

my $date = shift;

# Build the list of systems to test
my @desc_systems = <>;
my @list_systems = ();
my $systems = {};
foreach my $line (@desc_systems) 
{
    chomp($line);
    next if ($line =~ /^\s*#/);
    if ($line =~ /^\s*(\S+)\s*(.*)$/) {
	my $object = create_standard_object($1, $2);
	my $number = extract_object_number($1);
	my $name = get_standard_name($object);
	
	push @list_systems, $name;
	
	$systems->{$name}{"object"} = $object;
	$systems->{$name}{"number"} = $number;
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

    my $db = create_standard_object("DB::" . GT::Conf::get("DB::module"));
    my $q = $db->get_prices($code);
    my $calc = GT::Calculator->new($q);
    $calc->set_code($code);

    if ($timeframe)
    {
	$calc->set_current_timeframe(
	            GT::DateTime::name_to_timeframe($timeframe));
    }

    my $c = $calc->prices->count;
    my $last = $c - 1;
    my $first = $c - 2 * GT::DateTime::timeframe_ratio($YEAR,
					       $calc->current_timeframe);
    $first = 0 if ($full);
    $first = 0 if ($first < 0);
    if ($start) {
	my $ndate = $calc->prices->find_nearest_following_date($start);
	$first = $calc->prices->date($ndate);
    }
    if ($end) {
	my $ndate = $calc->prices->find_nearest_preceding_date($end);
	$last = $calc->prices->date($ndate);
    }
    
    my $i;
    if ($calc->prices->has_date($date)) {
	$i = $calc->prices->date($date);
    } else {
	my $ndate = $calc->prices->find_nearest_preceding_date($date);
	$i = $calc->prices->find_nearest_date($ndate);
    }

    my $n = 0;
    foreach (@list_systems)
    {
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
    }

    $db->disconnect;
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
	foreach my $code (sort { $a <=> $b || $a cmp $b } @{$systems->{$name}{'buy_signals'}}) {
	    display_item($db, $code, $html, $url);
	}
	print "</ul>" if ($html);
	print "<p>" if ($html);
	print "\nSell signal: $name\n";
	print "</p>" if ($html);
	print "<ul>" if ($html);
	foreach my $code (sort { $a <=> $b || $a cmp $b } @{$systems->{$name}{'sell_signals'}}) {
	    display_item($db, $code, $html, $url);
	}
	print "</ul>" if ($html);
    } elsif (ref($object) =~ /GT::Signals/) {
	print "<p>" if ($html);
	print "\nSignal: $name\n";
	print "</p>" if ($html);
	print "<ul>" if ($html);
	foreach my $code (sort { $a <=> $b || $a cmp $b } @{$systems->{$name}{'signals'}}) {
	    display_item($db, $code, $html, $url);
	}
	print "</ul>" if ($html);
    }
}
$db->disconnect;

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
	print " $code - $name\n";
    }
}
