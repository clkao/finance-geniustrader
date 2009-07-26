
package Finance::GeniusTrader::DB::pg;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

use Finance::GeniusTrader::DB;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Conf;
use Finance::GeniusTrader::DateTime;

use DBD::Pg;

@ISA = qw(Finance::GeniusTrader::DB);

=head1 NAME

Finance::GeniusTrader::DB::pg - Access to PostgreSQL database of quotes

=head1 DESCRIPTION

This module is used to retry quotes from a Postgresql database.
By default, the database is supposed to be running on localhost and
the only authentication done is the standard Unix one.

=head2 Configuration

You can put some configuration items in ~/.gt/options to indicate where
the database is.

=over 

=item DB::pg::dbname : the name of the database ("cours" by default)

=item DB::pg::dbhost : the host of the database ("" = localhost by default)

=item DB::pg::dbuser : the user account on the database

=item DB::pg::dbpasswd : the password of the user account

=back

=head2 Functions

=over

=item C<< Finance::GeniusTrader::DB::pg->new() >>

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    Finance::GeniusTrader::Conf::default("DB::pg::dbname", "cours");
    Finance::GeniusTrader::Conf::default("DB::pg::dbhost", "");   #aka localhost
    Finance::GeniusTrader::Conf::default("DB::pg::dbuser", "");   #aka current user
    Finance::GeniusTrader::Conf::default("DB::pg::dbpasswd", ""); #aka user is already identified

    my $self = { 'dbname'   => Finance::GeniusTrader::Conf::get("DB::pg::dbname"),
    		 'dbhost'   => Finance::GeniusTrader::Conf::get("DB::pg::dbhost"), 
		 'dbuser'   => Finance::GeniusTrader::Conf::get("DB::pg::dbuser"), 
		 'dbpasswd' => Finance::GeniusTrader::Conf::get("DB::pg::dbpasswd"), 
		 @_
		};
		
    my $connect_string = 'dbi:Pg:dbname=' . $self->{'dbname'};
    if ($self->{'dbhost'}) {
	$connect_string .= ";host=" . $self->{'dbhost'};
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
    my($self, $code, $timeframe) = @_;
    return get_last_prices($self, $code, -1, $timeframe);
}

=item C<< $db->get_last_prices($code, $limit, $timeframe) >>

Returns a Finance::GeniusTrader::Prices object containing the $limit last known prices for
the symbol $code.

=cut
sub get_last_prices {
    my ($self, $code, $limit, $timeframe) = @_;

    my $q = Finance::GeniusTrader::Prices->new($limit);
    $timeframe = $DAY unless ($timeframe);
    die "Intraday support not implemented in DB::pg" if ($timeframe < $DAY);
    return Finance::GeniusTrader::Prices->new() if ($timeframe > $DAY);

    $q->set_timeframe($timeframe);

    my $sql = qq{ SELECT first, high, low, last, volume, date
    		  FROM PRICES_$code ORDER BY date DESC };
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

    my $sql = "SELECT name FROM shares WHERE code = '$code'";
    my $sth = $self->{'_dbh'}->prepare($sql) || die $self->{'_dbh'}->errstr;
    $sth->execute() || die $self->{'_dbh'}->errstr;
    my $res = $sth->fetchrow_arrayref;
    return $res->[0];
}

=pod

=back

=cut
1;
