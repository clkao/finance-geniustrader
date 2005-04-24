package OptimizeGT;

# OptimizeGT -- author: Oliver Bossert
# Copyright (C) 2003 Oliver Bossert

# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or any later version.

# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.

# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=head1 Optimize the performance of Geniustrader

This module can be used to improve the performance of any program
using the GeniusTrader modules (e.g. the scripts graphic.pl,
backtest.pl, ...).

To use the module you have to make sure that you have write
permission for the directory the variable $newpath points to.

Next you have to insert the following two lines B<above> any other
use- or require-statement that includes a GT-module:

C<use OptimizeGT;>

C<use lib $OptimizeGT::newpath;>

Now you can use the script the normal way. When you first call the
script this module will need a little bit of time to do some
optimization stuff but therefore the next run will be much faster.

If you normally don't change your version of GT but simply use it, then
you can set the variable $PERIODIC_UPDATE to a higher value. If this
variable is non-zero the script is looking only every $PERIODIC_UPDATE
seconds for an update of the GT-modules. In this case it might be that
changes on a module are not detected and a old version is use instead!

=head2 Warning

This module is using regular expressions to modify the GT modules
source code on disk. This might lead to a problem if the one of the
function names that should be replaced is osed in a different context.

If your program produces an error you don't understand please you
should try to comment out the two lines mentioned above.

=cut

use strict;
use warnings;
use vars qw($newpath);

use File::Find;
use Carp::Datum::Strip qw(datum_strip);

$newpath = "/tmp";

my $TIMESTAMP = $newpath . "/gto-timestamp";
my $PERIODIC_UPDATE = 0;

my ($atstamp, $mtstamp) = (stat($TIMESTAMP))[8,9];
my $actual_time = time();

if (!defined($mtstamp) || $actual_time - $PERIODIC_UPDATE > $mtstamp) {

  my $path = "";
  foreach ( @INC ) {
    if ( -e $_ . "/GT/Conf.pm" ) {
      $path = $_;
      last;
    }
  }

  mkdir($newpath . "/GT");
  if ( $path ne "" ) {
    find sub { 
      my $source = $File::Find::name;
      my $dest = $File::Find::name;
      my $path_quote = quotemeta( $path );
      $dest =~ s/^$path_quote/$newpath/;

      if ( -d $_ ) {
	mkdir ($dest);
      } else {
	my ($atime, $s_time) = (stat($_))[8,9];
	my $d_time = 0;
	$d_time = (stat($dest))[9] if (-r $dest);

	if ($s_time != $d_time && $_ =~ /pm$/) {

	  datum_strip( $_, $dest );

	  open CODE, $dest or die("Cannot open $dest for reading");
	  my $code = join("", <CODE>);
	  close CODE;

	  $code =~ s/\$([\w\d\-_>]+)->is_available\(\s*(\$[\-\w\d_>]+)\s*,\s*(\$[\w\d\-_>]+)\s*\)/defined(\$$1\->{'values'}{$2}[$3]) ? 1 : 0/mg;
	  $code =~ s/^\s*DTRACE.*?;//sg;
	  $code =~ s/->get_name\(([\$\w\d\-_]+)\)/->{'names'}[$1]/mg;
	  $code =~ s/->get_name(\(\)){0,1}/->{'names'}[0]/mg;
	  $code =~ s/calc->indicators(\(\)){0,1}/calc->{'_indics'}/mg;

	  open CODE, ">$dest" or die("Cannot open $dest for writing");
	  print CODE $code;
	  close CODE;

	  utime($atime, $s_time, $dest);

	}
      }
    }, $path . "/GT";
  }


  if (! -r $TIMESTAMP) {
    open T, ">$TIMESTAMP" or warn "Could not write $TIMESTAMP";
    print T "Geniustrader Timestamp";
    close T;
  } else {
    utime($atstamp, $actual_time, $TIMESTAMP);
  }

}



#print STDERR "OptimizeGT took " . (time()-$actual_time) . " seconds\n";

1;
