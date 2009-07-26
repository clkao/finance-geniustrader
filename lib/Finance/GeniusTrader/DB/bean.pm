package Finance::GeniusTrader::DB::bean;

# Copyright 2003 Sai-kee Wong
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

use Finance::GeniusTrader::DB;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Conf;
use Finance::GeniusTrader::DateTime;
use DBI;

@ISA = qw(Finance::GeniusTrader::DB);

=head1 NAME

Finance::GeniusTrader::DB::bean - Access to beancounter database of quotes

=head1 DESCRIPTION

This module is used to retrieve quotes from a MySQL/PostgreSQL database
as setup by beancounter.
By default, the database is supposed to be running on localhost and
the only authentication done is the standard Unix one.

=head2 Configuration

You can put some configuration items in ~/.gt/options to indicate where
the database is.

=over 

=item DB::bean::dbname : the name of the database ("beancounter" by default)

=item DB::bean::dbhost : the host of the database ("" = localhost by default)

=item DB::bean::dbport : the port where the server is running ("" = default port number)

=item DB::bean::dbuser : the user account on the database (current user by default)

=item DB::bean::dbpasswd : the password of the user account

=item DB::bean::db : the database being used (mysql|Pg) ("mysql" by default)

=back

=head2 Functions

=over

=item C<< Finance::GeniusTrader::DB::mysql->new() >>

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    Finance::GeniusTrader::Conf::default("DB::bean::dbname", "beancounter");
    Finance::GeniusTrader::Conf::default("DB::bean::dbhost", "");  #aka localhost
    Finance::GeniusTrader::Conf::default("DB::bean::dbport", "");  #aka std port
    Finance::GeniusTrader::Conf::default("DB::bean::dbuser", "");  #aka current user
    Finance::GeniusTrader::Conf::default("DB::bean::dbpasswd", "");#aka user is already identified
    Finance::GeniusTrader::Conf::default("DB::bean::db", "mysql");

    # Avoid problem with careless users
    if (Finance::GeniusTrader::Conf::get("DB::bean::db") eq "pg") {
	Finance::GeniusTrader::Conf::set("DB::bean::db", "Pg");
    }
    

    eval "use DBD::" . Finance::GeniusTrader::Conf::get("DB::bean::db") . ";";

    my $self = { 'dbname'   => Finance::GeniusTrader::Conf::get("DB::bean::dbname"),
    		 'dbhost'   => Finance::GeniusTrader::Conf::get("DB::bean::dbhost"),
    		 'dbport'   => Finance::GeniusTrader::Conf::get("DB::bean::dbport"),
		 'dbuser'   => Finance::GeniusTrader::Conf::get("DB::bean::dbuser"),
		 'dbpasswd' => Finance::GeniusTrader::Conf::get("DB::bean::dbpasswd"),
		 @_
		};
		
    my $connect_string = 'dbi:' . Finance::GeniusTrader::Conf::get("DB::bean::db") .
                            ':dbname=' . $self->{'dbname'};
    if ($self->{'dbhost'}) {
	$connect_string .= ";host=" . $self->{'dbhost'};
    }
    if ($self->{'dbport'}) {
	$connect_string .= ";port=" . $self->{'dbport'};
    }
    $self->{'_dbh'} = DBI->connect($connect_string, $self->{'dbuser'},
    		$self->{'dbpasswd'}) || die "Couldn't connect to database !\n";

    return bless $self, $class;
}

=item C<< $db->disconnect >>

Disconnects from the database.

=cut
sub disconnect {
    my $self = shift;
    $self->{'_dbh'}->disconnect;
    delete $self->{'prices'};
    delete $self->{'dates'};
}

=item C<< $db->get_prices($code, $timeframe) >>

Returns a Finance::GeniusTrader::Prices object containing all known prices for the symbol $code.

=cut
sub get_prices {
    return get_last_prices(@_, -1);
}

=item C<< $db->get_last_prices($code, $limit, $timeframe) >>

Returns a Finance::GeniusTrader::Prices object containing the $limit last known prices for
the symbol $code.

Notice that beancounter only supports daily data, therefore it will
throw an error if you try to retrieve data in timeframes smaller than daily.

=cut
sub get_last_prices {
    my ($self, $code, $limit, $timeframe) = @_;

    $timeframe = $DAY unless($timeframe);
    die "The beancounter DB module does not support intraday data.\n" if ($timeframe < $DAY);
    return Finance::GeniusTrader::Prices->new() if ($timeframe > $DAY);

    my $q = Finance::GeniusTrader::Prices->new($limit);
    $q->set_timeframe($timeframe);

    my $sql = qq{ SELECT day_open, day_high, day_low, day_close, volume, date
    		  FROM stockprices WHERE symbol = '$code' ORDER BY date DESC };
    if ($limit > 0) {
	$sql .= "LIMIT $limit";
    }
    my $sth = $self->{'_dbh'}->prepare($sql) 
    	|| die $self->{'_dbh'}->errstr;
    $sth->execute() || die $self->{'_dbh'}->errstr;
    my $array_ref = $sth->fetchall_arrayref(  );
    $q->add_prices_array(reverse(@$array_ref));
    return $q;
}

=item C<< $db->get_db_name($code) >>

Returns the name of the stock designated by $code.

=cut
sub get_db_name {
    my ($self, $code) = @_;

    my $sql = "SELECT name FROM stockinfo WHERE symbol = '$code'";
    my $sth = $self->{'_dbh'}->prepare($sql) || die $self->{'_dbh'}->errstr;
    $sth->execute() || die $self->{'_dbh'}->errstr;
    my $res = $sth->fetchrow_arrayref;
    return $res->[0];
}

=pod

=back

=cut
1;
