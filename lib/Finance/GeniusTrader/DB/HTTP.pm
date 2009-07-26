package Finance::GeniusTrader::DB::HTTP;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

use Finance::GeniusTrader::DB;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Conf;
use Finance::GeniusTrader::DateTime;
use LWP;
use POSIX;

=head1 NAME

DB::HTTP - Retrieve prices from a CGI

=head1 DESCRIPTION

=head2 Overview

This access module enable you to download prices from a remote server
using a CGI script (cf web/quotes.pl).

=head2 Configuration

Most configuration items have default values, to alter these defaults
you must indicate the configuration item and its value in your
$HOME/.gt/options file, especially for authentification purpose.

=over

=item DB::module	HTTP

Informs gt you are using the HTTP.pm module. This
configuration item is always required in your $HOME/.gt/options file.

=item DB::HTTP::url : The URL that will be requested to download

=item DB::HTTP::location : The location of the server (www.geniustrader.org)

=item DB::HTTP::zone : The server zone (ie: admin)

=item DB::HTTP::username : The user name (ie : guest)

=item DB::HTTP::password : The password (ie : anonymous)

=item DB::HTTP::marker	string 

Delimits fields in each row of the data file.
The marker defaults to the tab character '\t'.

=item DB::HTTP::header_lines	number

The number of header lines in your data file
that are to be skipped during processing. Lines with the either the
comment symbol '#' or the less than symbol '<' as the first character
do not need to be included in this value.. The header_lines default value is 0.

=item DB::HTTP::format                0|1|2|3 (default is 3)
The format of the date/time string. Valid values are: 
0 - yyyy-mm-dd hh:nn:ss (the time string is optional)
1 - US Format (month before day, any format understood by Date::Calc)
2 - European Format (day before month, any format understood by Date::Calc)
3 - Any format understood by Date::Manip

=item DB::HTTP::fields::datetime	number

Column index where to find the period datetime
field. Indexes are 0 based.  For the particular case of datetime, can contain
multiple indexes, useful when date and time are separate columns in the data
file.  The date time format is anything that can be understood by Date::Manip.
A typical example would be YYYY-MM-DD HH:NN:SS. The default datetime index is 5.

=item DB::HTTP::fields::open	number

Column index where to find the period open field.
Indexes are 0 based. The default open index is 0.

=item DB::HTTP::fields::low	number

Column index where to find the period low field.
Indexes are 0 based. The default low index is 2. 

=item DB::HTTP::fields::high	number

Column index where to find the period high field.
Indexes are 0 based. The default high index is 1.

=item DB::HTTP::fields::close	number

Column index where to find the period close field.
Indexes are 0 based. The default close index is 3.

=item DB::HTTP::fields::volume	number

Column index where to find the period volume field.
Indexes are 0 based. The default volume index is 4.

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

    Finance::GeniusTrader::Conf::default("DB::HTTP::directory",
		      Finance::GeniusTrader::Conf::_get_home_path() . "/.gt/http-db-cache");
    Finance::GeniusTrader::Conf::default('DB::HTTP::header_lines', '0');
    Finance::GeniusTrader::Conf::default('DB::HTTP::marker', "\t");
    Finance::GeniusTrader::Conf::default('DB::HTTP::file_extension', '.txt');
    Finance::GeniusTrader::Conf::default('DB::HTTP::format', '3');
    Finance::GeniusTrader::Conf::default('DB::HTTP::fields::datetime', '5');
    Finance::GeniusTrader::Conf::default('DB::HTTP::fields::open', '0');
    Finance::GeniusTrader::Conf::default('DB::HTTP::fields::low', '2');
    Finance::GeniusTrader::Conf::default('DB::HTTP::fields::high', '1');
    Finance::GeniusTrader::Conf::default('DB::HTTP::fields::close', '3');
    Finance::GeniusTrader::Conf::default('DB::HTTP::fields::volume', '4');

    my $self = { "directory" => Finance::GeniusTrader::Conf::get("DB::HTTP::directory"),
		 "header_lines" => Finance::GeniusTrader::Conf::get('DB::HTTP::header_lines'),
		 "mark" => Finance::GeniusTrader::Conf::get('DB::HTTP::marker'),
		 "date_format" => Finance::GeniusTrader::Conf::get('DB::HTTP::format'),
		 "extension" => Finance::GeniusTrader::Conf::get('DB::HTTP::file_extension'),
		 "datetime" => Finance::GeniusTrader::Conf::get('DB::HTTP::fields::datetime'),
		 "open" => Finance::GeniusTrader::Conf::get('DB::HTTP::fields::open'),
		 "low" => Finance::GeniusTrader::Conf::get('DB::HTTP::fields::low'),
		 "high" => Finance::GeniusTrader::Conf::get('DB::HTTP::fields::high'),
		 "close" => Finance::GeniusTrader::Conf::get('DB::HTTP::fields::close'),
		 "volume" => Finance::GeniusTrader::Conf::get('DB::HTTP::fields::volume'),
                 "url" => Finance::GeniusTrader::Conf::get("DB::HTTP::url"),
                 "location" => Finance::GeniusTrader::Conf::get("DB::HTTP::location"),
                 "zone" => Finance::GeniusTrader::Conf::get("DB::HTTP::zone"),
                 "username" => Finance::GeniusTrader::Conf::get("DB::HTTP::username"),
                 "password" => Finance::GeniusTrader::Conf::get("DB::HTTP::password")
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


=item C<< $db->get_prices($code, $timeframe) >>

Returns a Finance::GeniusTrader::Prices object containing all known prices for the symbol $code.

=cut
sub get_prices {
    my ($self, $code, $timeframe) = @_;
    $timeframe = $DAY unless ($timeframe);
    die "Intraday support not implemented in DB::HTTP" if ($timeframe < $DAY);
    return Finance::GeniusTrader::Prices->new() if ($timeframe > $DAY);

    my $prices = Finance::GeniusTrader::Prices->new();
    $prices->set_timeframe($timeframe);

    my %fields = ('open' => $self->{'open'}, 'high' => $self->{'high'},
                  'low' => $self->{'low'}, 'close' => $self->{'close'},
		  'volume' => $self->{'volume'}, 'date' => $self->{'datetime'});
    $self->{'fields'} = \%fields;

    my $file = $self->download_prices($code);
		  
    $prices->loadtxt($file, $self->{'mark'}, $self->{'date_format'},
		     $self->{'header_lines'}, %fields);
    return $prices;
}

=item C<< $db->get_last_prices($code, $limit, $timeframe) >>

NOT SUPPORTED for HTTP db.

Returns a Finance::GeniusTrader::Prices object containing the $limit last known prices for
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
    my $prices = Finance::GeniusTrader::Prices->new();
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
	my $new_prices = Finance::GeniusTrader::Prices->new();
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
