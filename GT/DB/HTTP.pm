package GT::DB::HTTP;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

use GT::DB;
use GT::Prices;
use GT::Conf;
use GT::DateTime;
use LWP;
use POSIX;

=head1 NAME

DB::HTTP - Retrieve prices from a CGI

=head1 DESCRIPTION

=head2 Overview

This access module enable you to download prices from a remote server
using a CGI script (cf web/quotes.pl).

=head2 Configuration

You must set some configuration items in ~/.gt/options, especially for authentification purpose.

=over

=item DB::HTTP::url : The URL that will be requested to download

=item DB::HTTP::location : The location of the server (www.geniustrader.org)

=item DB::HTTP::zone : The server zone (ie: admin)

=item DB::HTTP::username : The user name (ie : guest)

=item DB::HTTP::password : The password (ie : anonymous)

=back

You can set the DB::HTTP::directory configuration item to tell where
the quotes are cached.

=head2 Functions

=over

=item C<< new() >>

Create a new DB object used to retry quotes from a CGI on a remote
server.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    GT::Conf::default("DB::HTTP::directory",
		      GT::Conf::_get_home_path() . "/.gt/http-db-cache");
    
    my $self = { "directory" => GT::Conf::get("DB::HTTP::directory"),
                 "url" => GT::Conf::get("DB::HTTP::url"),
                 "location" => GT::Conf::get("DB::HTTP::location"),
                 "zone" => GT::Conf::get("DB::HTTP::zone"),
                 "username" => GT::Conf::get("DB::HTTP::username"),
                 "password" => GT::Conf::get("DB::HTTP::password")
               };
    
    return bless $self, $class;
}

=item C<< $db->disconnect >>

Disconnects from the database.

=cut
sub disconnect {
    my $self = shift;
}

=item C<< $db->set_directory("/new/directory") >>

Indicate the directory containing all the cached data.

=cut
sub set_directory {
    my ($self, $dir) = @_;
    $self->{'directory'} = $dir;
}


=item C<< $db->set_options($mark, $date_format, %fields) >>

Set up all available options required to load text files.

By default :

 - Mark is a tabulation ("\t")
 - Date Format
    0 : GeniusTrader Date Format
    1 : US sort of Date Format
    2 : EU sort of Date Format
 - Fields Map
     %fields = ('open' => 0, 'high' => 1, 'low' => 2, 'close' => 3,
     %'volume' => 4, 'date' => 5);

=cut
sub set_options {
    my ($self, $mark, $date_format, %fields) = @_;

    if ($mark) { $self->{'mark'} = $mark; }
    if ($date_format) {$self->{'date_format'} = $date_format; }
    if (%fields) {
	$self->{'open'} = $fields{'open'};
	$self->{'high'} = $fields{'high'};
	$self->{'low'} = $fields{'low'};
	$self->{'close'} = $fields{'close'};
	$self->{'volume'} = $fields{'volume'};
	$self->{'date'} = $fields{'date'};
    }
}

=item C<< $db->get_prices($code, $timeframe) >>

Returns a GT::Prices object containing all known prices for the symbol $code.

=cut
sub get_prices {
    my ($self, $code, $timeframe) = @_;
	$timeframe = $DAY unless ($timeframe);
    die "Intraday support not implemented in DB::HTTP" if ($timeframe < $DAY);
    return GT::Prices->new() if ($timeframe > $DAY);

    my $prices = GT::Prices->new();
    $prices->set_timeframe($timeframe);

    if (!$self->{'mark'}) { $self->{'mark'} = "\t"; }
    if (!$self->{'date_format'}) { $self->{'date_format'} = 0; }
    if (!$self->{'open'}) { $self->{'open'} = 0; }
    if (!$self->{'high'}) { $self->{'high'} = 1; }
    if (!$self->{'low'}) { $self->{'low'} = 2; }
    if (!$self->{'close'}) { $self->{'close'} = 3; }
    if (!$self->{'volume'}) { $self->{'volume'} = 4; }
    if (!$self->{'date'}) { $self->{'date'} = 5; }
 
    my %fields = ('open' => $self->{'open'}, 'high' => $self->{'high'},
                  'low' => $self->{'low'}, 'close' => $self->{'close'},
		  'volume' => $self->{'volume'}, 'date' => $self->{'date'});
    $self->{'fields'} = \%fields;

    my $file = $self->download_prices($code);
		  
    $prices->loadtxt($file, $self->{'mark'}, $self->{'date_format'},
		     %fields);
    return $prices;
}

=item C<< $db->get_last_prices($code, $limit, $timeframe) >>

NOT SUPPORTED for HTTP db.

Returns a GT::Prices object containing the $limit last known prices for
the symbol $code.

=cut
sub get_last_prices {
    my ($self, $code, $limit, $timeframe) = @_;

    return get_prices($self, $code, $timeframe) if ($limit==-1);
    die "get_last_prices not supported with HTTP database\n";
}

sub download_prices {
    my ($self, $code) = @_;

    # Create a new directory if it doesn't already exist
    if (! -d $self->{'directory'})
    {
	mkdir $self->{'directory'};
    }

    # Do not request again a file already in the cache directory,
    # when the local file is less than 16 hours old.
    my $cache_file = "$self->{'directory'}/$code.txt";
    if (-e $cache_file && ( (stat(_))[9] > time - 16 * 3600 ))
    {
	return $cache_file;
    }

    # At this point, we know that our local file needs to be update.
    # Have a look at the latest date available on our local set of
    # data and request quotes to the server since then.
    my ($latest_date, $last_close);
    my $prices = GT::Prices->new();
    $prices->set_timeframe($DAY);
    if (-e $cache_file) {
        $prices->loadtxt($cache_file);

        my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime;
        my $today = sprintf("%04d-%02d-%02d", $y + 1900, $m + 1, $d);
        $latest_date = $prices->find_nearest_date($today);
	$last_close = $prices->at_date($latest_date)->[$CLOSE];
    }
    
    # Set up a new UserAgent with credentials
    my $ua = new LWP::UserAgent;
    $ua->agent("GeniusTrader HTTP method/0.2");
    if (defined($self->{'username'}) &&
	defined($self->{'password'})) {
	$ua->credentials($self->{'location'}, $self->{'zone'},
			 $self->{'username'}, $self->{'password'});
    }
    
    # Create a new HTTP request to download data for $code since $latest_date
    my $args = "?code=$code";
    $args .= "&since=$latest_date" if (defined($latest_date) && $latest_date);
    $args .= "&lastclose=$last_close" if (defined($last_close) && $last_close);
    my $req = new HTTP::Request GET => $self->{'url'} . $args;

    # Download and update the cache file
    my $res = $ua->request($req);
    if ($res->is_success)
    {
	open (CACHE, "> $cache_file.tmp") ||
	    die "Can't write in $cache_file.tmp : $!\n";
	print CACHE $res->content;
	close CACHE;
	my $new_prices = GT::Prices->new();
	$new_prices->loadtxt("$cache_file.tmp", $self->{'mark'}, $self->{'date_format'}, %{$self->{'fields'}});
	$new_prices->set_timeframe($DAY);
	for(my $i = 0; $i < $new_prices->count(); $i++) {
	    if ($prices->has_date($new_prices->at($i)->[$DATE])) {
		my $new_p = $new_prices->at($i);
		my $p = $prices->at_date($new_p->[$DATE]);
		$p->[$OPEN] = $new_p->[$OPEN];
		$p->[$HIGH] = $new_p->[$HIGH];
		$p->[$LOW] = $new_p->[$LOW];
		$p->[$CLOSE] = $new_p->[$CLOSE];
		$p->[$VOLUME] = $new_p->[$VOLUME];
	    } else {
		$prices->add_prices( [ @{$new_prices->at($i)} ] );
	    }
	}
	$prices->savetxt($cache_file);
	unlink "$cache_file.tmp";
    } else {
	die "Download failed.\n";
    }    
    return $cache_file;
}

=pod

=back

=cut
1;
