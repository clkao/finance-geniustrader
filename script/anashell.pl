#!/usr/bin/perl -w

# anashell.pl -- author: Oliver Bossert
# Copyright (C) 2004 Oliver Bossert
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
#

use strict;

=head1 Analyzer - Shell

The command help shows you a comprehensive summary of the available
commands:

anashell> help

By typing set without a parameter it will show you the current settings:

anashell> set
Settings:
  expert => 1
  code => 13000
  system => Systems::Generic {S:Generic:CrossOverUp {I:SMA 20} {I:SMA 60}}
  {S:Generic:CrossOverDown {I:SMA 20} {I:SMA 60}} broker =>
  InteractiveBrokers first => auto tf => OneTrade full => 0 last => auto
  mm [0] => Basic cs => OppositeSignal

Most of the settings are very easy to understand:

  expert => 1
   If set to 1 every command that can't be interpreted by the internal
   parser is interpreted by perl.

  code => 13000
   The code :)

  system => Systems::Generic {S:Generic:CrossOverUp {I:SMA 20} {I:SMA 60}}
  {S:Generic:CrossOverDown {I:SMA 20} {I:SMA 60}}
   The System to test

  broker => InteractiveBrokers
   The broker

  first => auto
  last => auto
   Can be set to a date; auto results in the same settings as in
   backtest.pl

  tf => OneTrade
  mm [0] => Basic
  cs => OppositeSignal
   Tradefilters, Money-Management and Closing-Strategies

  full => 0
   Test the full history?

For our backtest we want to test the full history so we use:

anashell> set full 1

And we add one more closing-strategy by using the following command:

anashell> set +cs Stop::KeepRunUp 10

(set cs[1] Xxxxx would have changed the second array element)
After this we start the backtest...

anashell> btest
Tested ... ok in 104 seconds

...and view the result:

anashell> report report_summary.ash 

By using the HTML::Mason-framework you can generate every report you
want...

Now we can save the system to a directory

anashell> save TEST /tmp
Saved TEST in /tmp...

So that we can load it the next time we start a session:

anashell> load TEST /tmp
Loaded Portfolio TEST...

If we don't know the name of our system we can list all systems in the
directory:

anashell> list /tmp
 ==> SY:Generic {S:Generic:CrossOverUp {I:SMA 20 {I:Prices CLOSE}} {I:SMA
 60 {I:Prices CLOSE}}} {S:Generic:CrossOverDown {I:SMA 20 {I:Prices
 CLOSE}} {I:SMA 60 {I:Prices CLOSE}}}|TF:OneTrade
 50|CS:OppositeSignal|CS:Stop:KeepRunUp 10
      --> 13000

Now let's do some analysis on the backtest:

First I would like to know the costs for each trade

anashell> calc_array {A:OpenDate} {A:Costs}
Number  OpenDate[]      Costs[]
  [  0]   1993-05-13    20.76
  [  1]   1993-07-01    22.65
[...]
   [ 34]   2002-01-17    20.3

But we can also calculate the average cost of one trade:

anashell> calc {A:Avg {A:Costs}}
20.1568571428571

- you see it is the same as using an indicator...

Now let's do some graphics (make sure you have R (www.r-project.org)
installed):

anashell> @gain = calc_array("{A:NetGain}")
anashell> r_hist( \@gain )

You can also have a look at the distribution of the gains over time:

anashell> r_bar( \@gain )

Or we create a second array and see if there is a correlation between the
Duration of a trade and its gain...

anashell> @duration = calc_array("{A:Duration}")
r_corr( \@duration, \@gain )

Now let's leave the program and save the history for the next session:

anashell> bye
Exiting Olf's Analyzer...
Save settings? [Y/n]: Y

=head2 Requirements

  This module needs Term::ReadLine to process the interactive commands.

=cut

#use OptimizeGT;
#use lib $OptimizeGT::newpath;

use Finance::GeniusTrader::Analyzers::Process;
use Finance::GeniusTrader::Conf;

use Term::ReadLine;

Finance::GeniusTrader::Conf::load();

# $term is imported from Finance::GeniusTrader::Analyzers::Process
$term = Term::ReadLine->new("Olf's Analyzer");
my $OUT = $term->OUT() || *STDOUT;
my $cmd;

my $proc = Finance::GeniusTrader::Analyzers::Process->new();

#$SIG{__DIE__} = sub {
#  print("Error:\n",@_);
#};


# Process Commands from STDIN
#############################
if ( $#ARGV > -1 || ! -t STDIN ) {
  undef $term;
  while (<>) {
    print $proc->parse( $_ );
  }

# If no STDIN-Input, run interactive mode...
############################################
} else {
  print $proc->info();
  while ( defined($cmd = $term->readline('anashell> ') )) {
    chomp( $cmd );
    eval {
      print $proc->parse( $cmd );
    };
    print "Error:  $@\n" if ($@);
  }
}

$proc->disconnect();
exit;

