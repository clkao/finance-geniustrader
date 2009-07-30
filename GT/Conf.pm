package GT::Conf;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# enhancements by ras copyright 2007-2008
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

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

comments are permitted on data lines provided they can be distinguished from
positional arguments markers (e.g. #1, #2, etc). in order to do this any
trailing data line comment marker (#) must be surrounded by whitespace.
the code is a bit more forgiving, using this regex (\s+#[\s\D]+.$)

note that the comment must follow the end of the logical data line
and terminates at the end of the logical line. logical line means the
line after continuation processing has completed.

examples:
 
  Aliases::Global::TFS2[]	SY:TFS #1 #2 | CS:SY:TFS #1 # comment
  graphic::positions::buycolor	"[0,135,0]" # very dark green
  graphic::buysellarrows::buycolor	"[0,135,0,64]" # semitransparent dark green

 note: configuration keys are lower cased automatically regardless of how
       they are defined, but their values are as specified when defined

=head1 FUNCTIONS

=item C<< GT::Conf::load([ $file ]) >>

Load the configuration from the indicated file. If the file is omitted
then it looks at ~/.gt/options by default.

=cut

sub load {
    my ($file) = @_;
    $file = _get_home_path() . "/.gt/options" if (! defined($file));

    warn ("Could not find configuration file: $file") and return if (! -e $file);

    open (FILE, "<", $file) || die "Can't open $file: $!\n";
    while (<FILE>)
    {
	chomp;

        # ras hack -- allow multi-line values in gt options file
        if ( s/\\$// ) {        # detect and remove continuation \
            $_ .= <FILE>;           # concatenate to prior part
            redo unless eof;    # don't read past file eof
        }

	next if /^\s*#/;      # remove lines containing whitespace and/or comments
	next if /^\s*$/;      # remove blank lines
	s/^\s*//; s/\s*$//;   # remove leading and trailing whitespace

	tr/[ \t]/[ \t]/s;     # squeeze out multiple adjacent whitespaces

        # remove trailing comment
        # in order to distinguish between a comment and a positional argument
        # marker (e.g. #1, #2, etc) the comment marker must be followed by
        # either whitespace or a non-digit (\s+#[\s\D]+.$)
        s/(\s+#[\s\D]+.*)$//;

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

=item C<< GT::Conf::conf_dump( [ "regex" ] ) >>

Helper function, writes the entire configure key=value pairs on stderr.
code example: GT::Conf::conf_dump;

pass a perl regex string to filter the output

=cut

sub conf_dump {
    my ( $regex ) = @_;

    $regex = ".*" unless $regex;
    print STDERR "gt configuration file keys and values filtered using \"$regex\"\n";
    printf STDERR "%s\t%-36s\t%-s\n", "item", "key", "value";
    my $i = 0;
    foreach ( sort keys %conf ) {
        ( grep m/$regex/i, $_ )
         ? printf STDERR "%3d\t%-36s\t%-s\n", $i, $_, $conf{$_}
         : ();
        ++$i;
    }
    print STDERR "\n\n";
}

=pod

=back

=cut

=item C<< my $gt_root_dir = GT::Conf::get_gt_root() >>

Helper function, returns the gt root directory
which is the directory that contains GT and Scripts
directories, along with any others that may be there.
if that configuration key-value is unset check for the
environment variable GT_ROOT otherwise returns an empty string

=cut

sub get_gt_root {
    my $gtroot = get( 'GT::Root' );
    if ( $gtroot ) {
        return $gtroot;
    } elsif ( defined $ENV{'GT_ROOT'} ) {
        return $ENV{'GT_ROOT'};
    } else {
        return "";
    }
}


1;
