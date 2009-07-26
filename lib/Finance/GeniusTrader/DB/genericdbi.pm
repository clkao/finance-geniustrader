package Finance::GeniusTrader::DB::genericdbi;

# Copyright 2005 João Antunes Costa
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

use Finance::GeniusTrader::DB;
use Finance::GeniusTrader::Conf;
use Finance::GeniusTrader::DateTime qw();
use DBI;

@ISA = qw(Finance::GeniusTrader::DB);

=head1 NAME

Finance::GeniusTrader::DB::genericdbi - Access to any database of quotes, as long
as a dbi driver is available

=head1 DESCRIPTION

This module is used to retrieve quotes from your existing database


=head2 Configuration

You can put some configuration items in ~/.gt/options to indicate where
the database is.

=over 

=item DB::genericdbi::dbname : the name of the database

=item DB::genericdbi::dbhost : the host of the database

=item DB::genericdbi::dbport : the port where the server is running

=item DB::genericdbi::dbuser : the user account on the database

=item DB::genericdbi::dbpasswd : the password of the user account

=item DB::genericdbi::db : the database being used (mysql|Pg|...) ("mysql" by default)

=item DB::genericdbi::prices_sql : The query used to retrieve price data.


Make sure to retrieve the data in the following order:
open, high, low, close, volume, date/time

Also, make sure to retrieve the data ordered by date/time descending
Example:

	SELECT period_open, period_high, period_low, period_close, volume, Concat(date, ' ', time) FROM stockprices WHERE symbol = '$code' AND timeframe='$timeframe' ORDER BY Concat(date, ' ', time) DESC LIMIT $limit


=item DB::genericdbi::name_sql : The query used to retrieve a symbol's description.

Example:

	SELECT name FROM stockinfo WHERE symbol = '$code';

=back

=head2 Functions

=over

=item C<< Finance::GeniusTrader::DB::genericdbi->new() >>

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
	my $self = shift;

    Finance::GeniusTrader::Conf::default("DB::genericdbi::dbhost", "");  #aka localhost
    Finance::GeniusTrader::Conf::default("DB::genericdbi::dbport", "");  #aka std port
    Finance::GeniusTrader::Conf::default("DB::genericdbi::dbuser", "");  #aka current user
    Finance::GeniusTrader::Conf::default("DB::genericdbi::dbpasswd", "");#aka user is already identified
    Finance::GeniusTrader::Conf::default("DB::genericdbi::db", "mysql");

	my $dbdriver= Finance::GeniusTrader::Conf::get("DB::genericdbi::db");
	my $dbname	= Finance::GeniusTrader::Conf::get("DB::genericdbi::dbname");

	die("Invalid configuration. Please specify a valid dbi driver in your options file (DB::genericdbi::db)") unless ($dbdriver);
	die("Invalid configuration. Please specify a valid database name in your options file (DB::genericdbi::dbname)") unless ($dbname);

	eval "use DBD::" . $dbdriver . ";";

	my $dbhost	= Finance::GeniusTrader::Conf::get("DB::genericdbi::dbhost");
	my $dbport	= Finance::GeniusTrader::Conf::get("DB::genericdbi::dbport");
	my $dbuser	= Finance::GeniusTrader::Conf::get("DB::genericdbi::dbuser");
	my $dbpasswd= Finance::GeniusTrader::Conf::get("DB::genericdbi::dbpasswd");

    my $connect_string = "dbi:$dbdriver:dbname=$dbname";
	$connect_string .= ";host=$dbhost" if ($dbhost);
	$connect_string .= ";port=$dbport" if ($dbport);

    $self->{'_dbh'} = DBI->connect($connect_string, $dbuser,
    		$dbpasswd) || die "Couldn't connect to database !\n";

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
    my ($self, $code, $timeframe) = @_;
    return get_last_prices($self, $code, -1, $timeframe);
}

=item C<< $db->get_last_prices($code, $limit, $timeframe) >>

Returns a Finance::GeniusTrader::Prices object containing the $limit last known prices for
the symbol $code in the given $timeframe.

=cut
sub get_last_prices {
    my ($self, $code, $limit, $timeframe) = @_;
    $timeframe = $Finance::GeniusTrader::DateTime::DAY unless ($timeframe);
    $limit = 99999999 if ($limit==-1);

    my $q = Finance::GeniusTrader::Prices->new($limit);
    $q->set_timeframe($timeframe);

    my $sql = Finance::GeniusTrader::Conf::get("DB::genericdbi::prices_sql::$timeframe", Finance::GeniusTrader::Conf::get('DB::genericdbi::prices_sql'));
    die("Invalid configuration. You must specify a valid prices sql statment for your database in the options file") if (!defined($sql));
    $sql =~ s/\$code/$code/;
    my $tf_map_value = Finance::GeniusTrader::Conf::get("DB::genericdbi::tf_map::$timeframe",$timeframe);
    $sql =~ s/\$timeframe/$tf_map_value/;
    $sql =~ s/\$limit/$limit/;

    my $sth = $self->{'_dbh'}->prepare($sql)
        || die $self->{'_dbh'}->errstr;
    if ($sth->execute()) {# || die $self->{'_dbh'}->errstr;
        my $array_ref = $sth->fetchall_arrayref();
        $q->add_prices_array(reverse(@$array_ref));
    }
    return $q;
}

=item C<< $db->get_db_name($code) >>

Returns the name of the stock designated by $code.

=back

=cut
sub get_db_name {
    my ($self, $code) = @_;

    my $sql = Finance::GeniusTrader::Conf::get("DB::genericdbi::name_sql") || die("Invalid configuration. You must specify a valid name_sql sql statment for your database in the options file");
	$sql =~ s/\$code/$code/;

    my $sth = $self->{'_dbh'}->prepare($sql) || die $self->{'_dbh'}->errstr;
    $sth->execute() || die $self->{'_dbh'}->errstr;
    my $res = $sth->fetchrow_arrayref;
    return $res->[0];
}

1;
