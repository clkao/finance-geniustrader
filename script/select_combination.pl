#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

use Finance::GeniusTrader::BackTest::Spool;
use Finance::GeniusTrader::Report;
use Finance::GeniusTrader::Conf;
use Getopt::Long;
use Pod::Usage;

Finance::GeniusTrader::Conf::load();

=head2 select_combination.pl [ --limit-ratio <min_ratio_perf/draw_down> ] 
			     [ --limit-performance <min_perf> ] 
			     [ --set <set> ]

Display a list of the best "code <-> system" combination possible.
It selects the system with highest ration "performance / maw_draw_down".
You can decide to exclude some system if they have a ration less than a
minimum ration by using --limit-ration, you can also exclude systems
if they have a performance less than a minimum given by  --limit-performance.

=cut
my $set = '';
my ($limit_ratio, $limit_perf) = (0, 0);
my $man = 0;
my @options;
GetOptions("set=s" => \$set, "limit-ratio=s" => \$limit_ratio,
	   "limit-performance=s" => \$limit_perf,
	   "option=s" => \@options, "help!" => \$man);

foreach (@options) {
    my ($key, $value) = split (/=/, $_);
    Finance::GeniusTrader::Conf::set($key, $value);
}

pod2usage( -verbose => 2) if ($man);

my $outputdir = shift;
$outputdir = Finance::GeniusTrader::Conf::get("BackTest::Directory") if (! $outputdir);
$outputdir = "." if (! $outputdir);

my $spool = Finance::GeniusTrader::BackTest::Spool->new($outputdir);

my $l = $spool->list_available_data($set);

sub _get_name {
    my ($spool, $name) = @_;
    my $alias = $spool->get_alias_name($name);
    return $alias if (defined($alias) and $alias);
    return $name;
}

# Find all codes
my %codes;
foreach (keys %{$l})
{
    foreach my $code (@{$l->{$_}})
    {
	$codes{$code} = 1;
    }
}

# $spool->get_stats($sysname, $code) returns an array
# [0] std_perf
# [1] perf
# [2] max draw down
# [3] std_buyandhold
# [4] buyandhold

# Analysis by code
foreach my $code (sort keys %codes)
{
    my ($best_perf, $perf, $best_sys) = (0, 0, '');
    foreach (sort { ($spool->get_stats($b,$code)->[0] <=> 
		     $spool->get_stats($a,$code)->[0]) ||
		    ($spool->get_stats($b,$code)->[1] <=> 
		     $spool->get_stats($a,$code)->[1])
		  }
	     grep { defined($spool->get_stats($_,$code)) } 
	     keys %{$l})
    {
	my $ana = $spool->get_stats($_, $code);
	
	if ($ana->[2] > 0.05) {
	    $perf = $ana->[0] / $ana->[2];
	} else {
	    $perf = $ana->[0] / 0.05;
	}
	
	next if ($limit_ratio && ($perf < $limit_ratio));
	next if ($limit_perf && ($ana->[0] * 100 < $limit_perf));
	
	if ($perf > $best_perf)
	{
	    $best_sys = _get_name($spool, $_);
	}
    }
    print "$code $best_sys\n";
}


