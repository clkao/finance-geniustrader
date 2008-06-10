#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;

use GT::Report;
use GT::Conf;
use GT::BackTest::Spool;
use GT::Eval;
use Getopt::Long;
use Pod::Usage;

GT::Conf::load();


=head1 NAME

analyze_backtest.pl

=head1 SYNOPSIS

  ./analyze_backtest.pl 

=head1 OPTIONS

=over 4

=item --set=SETNAME

Restricts the analysis to a specific set. A set is simply an identifier that you put on data when you add it to the "backtests" directory (refer to your options file for the location of this directory) when using backtest_many.pl. Using the --set option you can differentiate between the different backtest results in your directory.

=item --template=<template file>

Output is generated using the indicated HTML::Mason component.
For Example, --template="analyze_backtest.mpl"
The template directory is defined as Template::directory in the options file.
Each template can be predefined by including it into the options file
For example, Template::analyze_backtest analyze_backtest.mpl

=item --options=<key>=<value>

A configuration option (typically given in the options file) in the
form of a key=value pair. For example,
 --option=DB::Text::format=0
sets the format used to parse markets via the DB::Text module to 0.

=back

=head1 DESCRIPTION

This tool runs an analysis against existing backtest spool files.
The location of the spool files is defined as BackTest::Directory in the options file.

=cut



my ($set, $template) = ('', '');
my $man = 0;
my @options;
GetOptions("set=s" => \$set, 'template=s' => \$template,
	   "option=s" => \@options, "help!" => \$man);

foreach (@options) {
    my ($key, $value) = split (/=/, $_);
    GT::Conf::set($key, $value);
}

pod2usage( -verbose => 2) if ($man);
my $outputdir = shift;
$outputdir = GT::Conf::get("BackTest::Directory") if (! $outputdir);
$outputdir = "." if (! $outputdir);

my $mason_template = GT::Conf::get('Template::analyze_backtest') if ($template eq '');
$template = $mason_template if defined $mason_template;

my $spool = GT::BackTest::Spool->new($outputdir);

if ($template ne '') {

   my $use = 'use HTML::Mason;use File::Spec;use Cwd;';
   eval $use;
   die(@!) if(@!);
 
   my $output;
   my $l = $spool->list_available_data($set);
   my $s = $spool;

   my $db = create_db_object();
   
   # Find all codes
   my %codes;
   foreach (keys %{$l}) {
      foreach my $code (@{$l->{$_}}) {
         $codes{$code} = 1;
      }
   }
   
   my $root = GT::Conf::get('Template::directory');
   $root = File::Spec->rel2abs( cwd() ) if (!defined($root));
   my $interp = HTML::Mason::Interp->new( comp_root => $root,
 					 out_method => \$output
 				       );
   $template='/' . $template unless ($template =~ /\\|\//);
   $interp->exec($template, s => $s, l => $l, codes => \%codes, db => $db);
   print $output;
   $db->disconnect;
} else { 
   GT::Report::AnalysisList($spool, $set);
}

