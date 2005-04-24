#!/usr/bin/perl -w

# Copyright 2004 Raphaël Hertzog
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
use GT::DateTime;
use Getopt::Long;
use Time::localtime;

GT::Conf::load();

=head1 NAME

manage_portfolio.pl

=head1 SYNOPSIS

  ./manage_portfolio.pl <portfolio> create [<initial-sum>]
  ./manage_portfolio.pl <portfolio> bought <quantity> <share> <price> [<date>]
  ./manage_portfolio.pl <portfolio> sold <quantity> <share> <price> [<date>]
  ./manage_portfolio.pl <portfolio> stop <share> <price>
  ./manage_portfolio.pl <portfolio> set initial-sum <sum of money>
  ./manage_portfolio.pl <portfolio> set broker <broker>
  ./manage_portfolio.pl <portfolio> report {performance|positions|historic|analysis}

=head1 OPTIONS

=over

=item --marged

Only useful for "bought" and "sold" commands. It explains that the corresponding
positions are marged, no personal money has been used for them, the money has been
rented. 

=item --source <source>

Useful to tag certain orders as the result of a particular strategy. All orders
passed by following the advice of someone could be tagged with his name and later
you'll be able to make stats on the performance you made with his advices.

=item --timeframe {day|week|...}

Tell how to parse the format of the date.

=item --since <date>

=item --until <date>

Those two options are used to restrict the result of a "report" command to
a certain timeframe.

=back

=head1 DESCRIPTION

This tool lets you create a portfolio object on your disk and update it
regularly, this can be used to create virtual portfolio to test how a stratgey
works in real time or to track your real portfolio and use GeniusTrader to
make some analysis on it.

The first parameter is a filename of a portfolio. The name is supposed to
be relative to the portfolio directory which is $HOME/.gt/portfolio in
Unix but can be overriden with the configuration item
GT::Portfolio::Directory. If it doesn't exist, it will try in the local
directory.

=cut

# Get all options
my ($marged, $source, $since, $until, $confirm, $timeframe) = 
    (0, '', '', '', 1, 'day');
GetOptions("marged!" => \$marged, "source=s" => \$source, 
	   "since=s" => \$since, "until=s" => \$until,
	   "confirm!" => \$confirm, "timeframe" => \$timeframe);

# Check the portfolio directory
GT::Conf::default("GT::Portfolio::Directory", $ENV{'HOME'} . "/.gt/portfolio");
my $pf_dir = GT::Conf::get("GT::Portfolio::Directory");
mkdir $pf_dir if (! -d $pf_dir);

# Load the portfolio
my $pfname = shift;
my $cmd = shift;
my $pf;

if ($pfname !~ m#^(./|/)#) {
    $pfname = "$pf_dir/$pfname";
}
if (-e $pfname) {
    $pf = GT::Portfolio->create_from_file($pfname);
} else {
    $pf = GT::Portfolio->new();
}

my $changes = 0;

# Creation of DB module
my $db = create_db_object();

if ($cmd eq "create") {
    
    $changes = 1;
    my $cash = shift;
    if (-e $pfname) {
	print "A portfolio with this name already exists. The current portfolio will be replaced !\n";
	my $pf = GT::Portfolio->new();
    } else {
	print "Creation of a new portfolio in $pfname...\n";
    }
    if (defined($cash)) {
	print "Setting initial sum to $cash.\n";
	$pf->set_initial_value($cash);
    }
    
} elsif (($cmd eq "bought") or ($cmd eq "sold")) {
    
    $changes = 1;
    my ($quantity, $code, $price, $date) = @ARGV;
    
    if (! defined($date)) {
	$date = sprintf("%04d-%02d-%02d", localtime->year + 1900, localtime->mon + 1, localtime->mday);
    }
    my $order = GT::Portfolio::Order->new;
    if ($cmd eq "bought") {
	$order->set_buy_order;
    } else {
	$order->set_sell_order;
    }	
    $order->set_type_limited;
    $order->set_price($price);
    $order->set_submission_date($date);
    $order->set_quantity($quantity);
    $order->set_source($source) if ($source);

    my $name = $db->get_name($code);
    # Look for open positions to complete
    my $pos = find_position($pf, $code, $source, $marged);
    if (! defined $pos) {
	if (defined($name) && $name) {
	    print "Creating a new position ($name - $code, $source).\n"; 
	} else {
	    print "Creating a new position ($code, $source).\n"; 
	}
	$pos = $pf->new_position($code, $source, $date);
	$pos->set_timeframe(GT::DateTime::name_to_timeframe($timeframe));
	if ($marged) {
	    $pos->set_marged();
	} else {
	    $pos->set_not_marged();
	}   
    }
    print "Applying order: $cmd $quantity at $price on $date.\n";
    $pf->apply_order_on_position($pos, $order, $price, $date);
    
} elsif ($cmd eq "stop") {

    my ($code, $price) = @ARGV;
    my $name = $db->get_name($code);
    
    my $pos = find_position($pf, $code, $source, $marged);
    if (! defined($pos)) {
	print "No corresponding open positions found.\n";
    } else {
	$changes = 1;
	$pos->force_stop($price);
	if (defined($name) && $name) {
	    print "Setting the stop level of $name - $code to $price.\n";
	} else {
	    print "Setting the stop level of $code to $price.\n";
	}
    }
    
} elsif ($cmd eq "set") {

    $changes = 1;
    my ($var, $value) = @ARGV;
    if ($var eq "initial-sum") {
	print "Setting initial sum to $value.\n";
	$pf->set_initial_value($value);
    } elsif ($var eq "broker") {
	print "Setting broker to $value.\n";
	my $broker = create_standard_object("Brokers::$value");
	$pf->set_broker($broker);
    }
    
} elsif ($cmd eq "report") {
    
    my ($what) = @ARGV;

    my $db = create_db_object();
    if ($what eq "performance") {

    } elsif ($what eq "positions") {
	GT::Report::OpenPositions($pf, 1);
    } elsif ($what eq "historic") {
	GT::Report::Portfolio($pf, 1);
    } elsif ($what eq "analysis") {
	
    }
} else {
    print "${cmd}: Invalid command.\n";
}

if ($changes) {
    local $| = 1;
    my $is_confirmed = $confirm ? 0 : 1;
    if ($confirm) {
	print "\n-- Do you confirm all the above operations ? [Yn] ";
	my $ans = <STDIN>;
	chomp($ans);
	if ($ans =~ /^(Y|y|)$/) {
	    print "Applying all the planned changes !\n";
	    $is_confirmed = 1;
	} else {
	    print "Discarding all the planned changes !\n";
	    $is_confirmed = 0;
	}
    }
    if ($is_confirmed) {
	print "Storing changes ... ";
	$pf->store($pfname);
	print "done.\n"
    }
}

$db->disconnect;

sub find_position {
    my ($pf, $code, $source, $marged) = @_;
    my $pos;
    foreach ($pf->get_position($code, $source)) {
	next if (! defined($_));
	if ($marged) {
	   $pos = $_ if ($_->is_marged); 
	} else {
	   $pos = $_ if (! $_->is_marged); 
	}
    }
    return $pos;
}
