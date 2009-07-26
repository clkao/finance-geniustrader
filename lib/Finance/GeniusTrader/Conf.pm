package GT::Conf;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# baseline: 24 Apr 2005 2370 bytes
# revised based on update 01jan07
# $Id$

use strict;
use vars qw(%conf);

=head1 NAME

GT::Conf - Manage configuration

=head1 DESCRIPTION

This module provides functions to manage personal GeniusTrader configuration.
The configuration information are stored in file ~/.gt/options by default.

The configuration file format is similar to a perl hash, in other words, a key
followed by data for that key. keys are delimited from their value by whitespace.
key values can contain embedded whitespace.

key value strings can be continued across multiple lines by delimiting the
newline with a backslash (\) (watch out for trailing whitespace after the \ and
before the newline).

comments introduced with a # as the first character on a line. data lines
cannot contain a comment since the # character is used in many data strings.

blank lines and lines with only whitespace are ignored.

=head1 EXAMPLES of ~/.gt/options Entries

# this is an example of a comment

DB::module genericdbi

DB::bean::dbname beancounter

Graphic::Candle::UpBorderColor "[0,180,80]"

Graphic::Candle::DownBorderColor "[180,0,80]"

this example shows how continuing key values across lines can be useful.

DB::genericdbi::prices_sql SELECT day_open, day_high, day_low, \
  day_close, volume, date FROM stockprices WHERE symbol = '$code' ORDER \
  BY date DESC

the following shows why comments are not permitted on data lines:

Aliases::Global::TFS2[] SY:TFS #1 #2 | CS:SY:TFS #1

=over

=head1 FUNCTIONS

=item C<< GT::Conf::load([ $file ]) >>

Load the configuration from the indicated file. If the file is omitted
then it looks at ~/.gt/options by default.

=cut
sub load {
    my ($file) = @_;
    $file = _get_home_path() . "/.gt/options" if (! defined($file));

    warn ("Could not find configuration file: $file") and return if (! -e $file);

    # changed from "< $file" per pg 625 programming perl 3rd ed.
    open (FILE, "<", $file) || die "Can't open $file: $!\n";
    my $buf = '';
    while (<FILE>)
    {
	chomp;

        # ras hack -- allow multi-line values in gt options file
        if ( /\\$/ ) {
          s/\\//;             # remove \
          $buf .= $_;         # save line
          next;               # get next line
        } else {
          $_ = $buf . $_;     # collect complete line into $_
          $buf = '';          # reset line buffer
        }

	next if /^\s*#/;      # remove lines containing whitespace and/or comments
	next if /^\s*$/;      # remove blank lines
	s/^\s*//; s/\s*$//;   # remove leading and trailing whitespace

	tr/[ \t]/[ \t]/s;     # squeeze out multiple adjacent whitespaces

	my ($key, $val) = split /\s+/, $_, 2;
	$conf{lc($key)} = $val;
    }
    close FILE;

    # Load the various definition of aliases
    
    foreach my $kind ("Signals", "Indicators", "Systems", "CloseStrategy", 
                      "MoneyManagement", "TradeFilters", "OrderFactory",
                      "Analyzers")
    {
        foreach my $file (GT::Conf::_get_home_path()."/.gt/aliases/".lc($kind),
         GT::Conf::get("Path::Aliases::$kind"))
	{
	    next unless defined $file;
	    next if not -e $file;
            open(ALIAS, "<", "$file") || die "Can't open $file : $!\n";
	    while (defined($_=<ALIAS>)) {
		if (/^\s*(\S+)\s+(.*)$/) {
		    GT::Conf::default("Aliases::$kind\::$1", $2);
		}
	    }
	    close ALIAS;
	}
    }

}

=item C<< GT::Conf::clear() >>

Clear all the configuration.

=cut
sub clear { %conf = () }

=item C<< GT::Conf::store($file) >>

Write all the current configuration in the given file. Note: all prior
commentary, if any is lost.

=cut
sub store {
    my ($file) = @_;
    $file = _get_home_path() . "/.gt/options" if (! defined($file));

    # changed from "> $file" per pg 625 programming perl 3rd ed.
    open (FILE, ">", $file) || die "Can't write on $file: $!\n";
    foreach (sort keys %conf)
    {
	print FILE $_ . "\t" . $conf{$_} . "\n";
    }
    close FILE;
}

=item C<< GT::Conf::get($key,$defaultValue) >>

Return the configuration value for the given key. If the
key doesn't exist, it returns the optional defaultValue.

If neither the key nor defaultValue exist, it returns undef.

=cut
sub get { 
    my $value = $conf{lc($_[0])};
    return $value if (defined($value));
    return $_[1] if(defined($_[1]));
    return undef;
}

=item C<< GT::Conf::set($key, $value) >>

Set the given configuration item to the corresponding value. Replaces any
previous value.

=cut
sub set { $conf{lc($_[0])} = $_[1] }

=item C<< GT::Conf::default($key, $value) >>

Set a default value to the given item. Must be called by GT itself to
give reasonable default values to most of configurations items.

=cut
sub default {
    my ($key, $val) = @_;
    $key = lc($key);
    if (! defined($conf{$key}))
    {
	$conf{$key} = $val;
    }
}

=item C<< GT::Conf::get_first($key, ...) >>

Return the value of the first item that does have a non-zero value.

=cut
sub get_first {
    my (@keys) = @_;
    foreach (@keys) {
	my $value = get($_);
	if (defined($value) && $value) {
	    return $value;
	}
    }
    return "";
}

#Helper function, returns the home directory
#This is usually defined as the environment variable HOME on Unix like
#systems, and HOMEDRIVE + HOMEPATH on Windows

=item C<< GT::Conf::=_get_home_path() >>

Helper function, returns the home directory environment variable HOME on Unix
or on windows the environment variables HOMEDRIVE . HOMEPATH

=cut
sub _get_home_path {
    my $homedir = '';
    if (defined($ENV{'HOME'})) {
        $homedir = $ENV{'HOME'};
    } elsif (defined($ENV{'HOMEDRIVE'}) && defined($ENV{'HOMEPATH'})) {
        $homedir = $ENV{'HOMEDRIVE'} . $ENV{'HOMEPATH'};
    } else {
        warn "homedir not defined, may not be able to find configuration file";
    }
    return $homedir;
}

=pod

=back

=cut
1;
