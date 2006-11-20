package GT::Conf;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(%conf);

=head1 NAME

GT::Conf - Manage configuration

=head1 DESCRIPTION

This modules provides function to manage personal configuration. Those
informations are used to be stored in ~/.gt/

=over

=item C<< GT::Conf::load([ $file ]) >>

Load the configuration from the indicated file. If the file is omitted
then it looks at ~/.gt/options by default.

=cut
sub load {
    my ($file) = @_;
    $file = _get_home_path() . "/.gt/options" if (! defined($file));

    return if (! -e $file);
    
    open (FILE, "< $file") || die "Can't open $file: $!\n";
    while (<FILE>)
    {
	chomp;
	next if /^\s*#/;
	next if /^\s*$/;
	s/^\s*//; s/\s*$//;
	my ($key, $val) = split /\s+/, $_, 2;
	$conf{lc($key)} = $val;
    }
    close FILE;
}

=item C<< GT::Conf::clear() >>

Clear all the configuration.

=cut
sub clear { %conf = () }

=item C<< GT::Conf::store($file) >>

Write all the current configuration in the given file.

=cut
sub store {
    my ($file) = @_;
    $file = _get_home_path() . "/.gt/options" if (! defined($file));

    open (FILE, "> $file") || die "Can't write on $file: $!\n";
    foreach (sort keys %conf)
    {
	print FILE $_ . "\t" . $conf{$_} . "\n";
    }
    close FILE;
}

=item C<< GT::Conf::get($key) >>

Return the configuration value for the given key. Returns undef if the
key doesn't exist.

=cut
sub get { return $conf{lc($_[0])}; }

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

=pod

=back

=cut

#Helper function, returns the home directory
#This is usually defined as the environment variable HOME on Unix like
#systems, and HOMEDRIVE + HOMEPATH on Windows

sub _get_home_path {
	my $homedir = '';
	if (defined($ENV{HOME})) {
		$homedir = $ENV{HOME};
	} elsif (defined($ENV{HOMEDRIVE}) && defined($ENV{HOMEPATH})) {
		$homedir = $ENV{HOMEDRIVE} . $ENV{HOMEPATH};
	} else {
		warn "homedir not defined, may not be able to find configuration file";
	}
	return $homedir;
}

1;
