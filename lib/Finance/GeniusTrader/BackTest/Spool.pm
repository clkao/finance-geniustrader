package GT::BackTest::Spool;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use warnings;

use vars qw(@ISA);

use GT::Tools qw(:conf);
use GT::Serializable;
#ALL# use Log::Log4perl qw(:easy);

@ISA = qw(GT::Serializable);

=head1 GT::BackTest::Spool

This modules provides some functions to manage a backtest directory.

=head2 $spool = GT::BackTest::Spool->new($data_directory);

Create and initialize a BackTest::Spool object with a specific directory,
where backtest data are stored.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($directory) = @_;

    my $self = { "directory" => $directory,
		 "cache" => 1,
		 "index_modified" => 0 };

    # Open the index file of the specified directory
    if (-e "$directory/index") {
        $self->{'index'} = GT::BackTest::Spool::File->create_from_file("$directory/index");
    } else {
	$self->{'index'} = GT::BackTest::Spool::File->new();
	$self->{'index'}->store("$directory/index");
    }
    
    bless $self, $class;

    return $self;
}

=head2 $spool->use_cache(0|1)

Tell if data are cached before being written. Default to 1. In that
case you have to call $spool->sync from time to time to write data
on the disk.

=cut
sub use_cache {
    my ($self, $cache) = @_;
    $self->{'cache'} = $cache;
    $self->sync() if (! $cache);
}

=head2 $spool->update_index()

Force an update of the index data. Use that if a long time has elapsed since
the read and the index may have been updated.

=cut
sub update_index {
    my ($self) = @_;
    my $dir = $self->{'directory'};
    if ($self->{'index_modified'}) {
	warn "You just lost modifications to the index of backtests ...";
    }
    $self->{'index'} = GT::BackTest::Spool::File->create_from_file("$dir/index");
}

=head2 $spool->add_alias_name($sysname, $alias);

This function will link an alias and a system name.

=cut
sub add_alias_name {
    my ($self, $sysname, $alias) = @_;
    my $index = $self->{'index'};

    $index->{'alias'}{$sysname} = $alias;
    $self->{'index_modified'} = 1;
    $self->sync() if (! $self->{'cache'});

    return;
}

=head2 $spool->get_alias_name($sysname)

Return the alias name of the system if it exists.

=cut
sub get_alias_name {
    my ($self, $sysname) = @_;
    if (exists $self->{'index'}{'alias'}{$sysname}) {
	return $self->{'index'}{'alias'}{$sysname};
    }
    return undef;
}

=head2 $spool->add_results($sysname, $code, $stats, $portfolio, [$set]);

This function will add new data or update old ones in the spooler.

=cut

sub add_results {
    my ($self, $sysname, $code, $stats, $portfolio, $set) = @_;
    my $directory = $self->{'directory'};
    my $index = $self->{'index'};
    
    # Make sure $set is already defined, overwise initilize it
    if (! (defined($set) && $set)) {
        my $n = 1;
        while (-e "$directory/$code-$n.bkt") { $n++ }
        $set = $n;
    }
    
    # Open the "$code-$set.bkt" file if required
    if (! exists $self->{'bkt'}{"$code-$set"}) {
	if (-e "$directory/$code-$set.bkt") {
	    $self->{'bkt'}{"$code-$set"} = GT::BackTest::Spool::File->create_from_file("$directory/$code-$set.bkt");
	} else {
	    $self->{'bkt'}{"$code-$set"} = GT::BackTest::Spool::File->new();
	}
    }

    # Add $stats, $portfolio and $set values
    $index->{'results'}{$sysname}{$code} = $stats;
    $index->{'set'}{$sysname}{$code} = $set;
    $self->{'index_modified'} = 1;
    $self->{'bkt'}{"$code-$set"}{$sysname}{$code}{'portfolio'} = $portfolio;
    
    # Store updated data into right files
    $self->sync() if (! $self->{'cache'});
}

=head2 $spool->sync()

Write the cache on disk.

=cut
sub sync {
    my ($self) = @_;
    my $dir = $self->{'directory'};
    if ($self->{'index_modified'}) {
	$self->{'index'}->store("$dir/index");
	$self->{'index_modified'} = 0;
    }
    my @data = keys %{$self->{'bkt'}};
    foreach my $file (@data) {
	$self->{'bkt'}{$file}->store("$dir/$file.bkt");
	delete $self->{'bkt'}{$file};
    }
}

=head2 $hash = $spool->list_available_data([$set]);

This function will return a list of systems/codes available.
$hash->{$sysname} = [ list of codes ];

=cut
sub list_available_data {
    my ($self, $set) = @_;
    my $index = $self->{'index'};
    my %hash;

    foreach my $sysname (keys %{$index->{'results'}}) {
	my @codes;
	foreach my $code (keys %{$index->{'results'}{$sysname}}) {
	    if ((!(defined($set) and $set)) or 
		($index->{'set'}{$sysname}{$code} eq $set)) {
		push @codes, $code;
	    }
	}
	$hash{$sysname} = \@codes;
    }
    return \%hash;
}

=head2 $spool->get_stats($sysname, $code);

This function will return all stats available for a given $sysname and $code.

=cut
sub get_stats {
    my ($self, $sysname, $code) = @_;
    my $index = $self->{'index'};

    if (exists $index->{'results'}{$sysname}{$code}) {
	return $index->{'results'}{$sysname}{$code};
    }
    return undef;
}

=head2 $spool->get_portfolio($sysname, $code);

This function will return a portfolio for a given $sysname and $code.

=cut
sub get_portfolio {
    my ($self, $sysname, $code) = @_;
    my $directory = $self->{'directory'};
    my $index = $self->{'index'};

    # Get the full name of the system if we have an alias
    if ($sysname !~ /\|/) {
	my $alias = resolve_alias($sysname);
	die "Alias unknown '$sysname'" if (! $alias);
	$sysname = $alias;
    }
    
    my $set;
    if (exists $index->{'set'}{$sysname} and
	exists $index->{'set'}{$sysname}{$code})
    {
	$set = $index->{'set'}{$sysname}{$code};
    } else {
	warn "The data you're asking is not available in the spool.\n";
	return undef;
    }

    # Look in the cache first, otherwise load it from the file 
    if (exists $self->{'bkt'}{"$code-$set"}) {
	return $self->{'bkt'}{"$code-$set"}{$sysname}{$code}{'portfolio'};
    } elsif (-e "$directory/$code-$set.bkt") {
        my $bkt = GT::BackTest::Spool::File->create_from_file("$directory/$code-$set.bkt");
	return $bkt->{$sysname}{$code}{'portfolio'};
    }
    return undef;
}

package GT::BackTest::Spool::File;

use vars qw(@ISA);

@ISA = qw(GT::Serializable);

sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { };
    bless $self, $class;
    return $self;
}

1;
