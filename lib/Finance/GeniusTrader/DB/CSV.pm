package Finance::GeniusTrader::DB::CSV;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

use Finance::GeniusTrader::DB;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Conf;
use Finance::GeniusTrader::DateTime;
use Time::Local;

use DBI;

@ISA = qw(Finance::GeniusTrader::DB);

=head1 NAME

Finance::GeniusTrader::DB::CSV - Access to a text files by DBI::CSV

=head1 DESCRIPTION

This module handels the access to textfiles by using the
DBI:File-module.

=head2 Configuration

You can put some configuration items in ~/.gt/options to indicate where
the database is.

=over 

=item DB::csv::database : the type of the database ("CSV" by default)

=item DB::csv::dbname : the name of the database ("cours" by default)

=item DB::csv::dbhost : the host of the database ("" = localhost by default)

=item DB::csv::dbuser : the user account on the database

=item DB::csv::dbpasswd : the password of the user account

=back

=head2 Functions

=over

=item C<< Finance::GeniusTrader::DB::csv->new() >>

Creates a new database-object

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    Finance::GeniusTrader::Conf::default("DB::csv::database", "CSV");
    Finance::GeniusTrader::Conf::default("DB::csv::dbname", "/home/olf/ablage/private/finalize/GT/database"); 
    Finance::GeniusTrader::Conf::default("DB::csv::dbhost", "");   #aka localhost
    Finance::GeniusTrader::Conf::default("DB::csv::dbuser", "");   #aka current user
    Finance::GeniusTrader::Conf::default("DB::csv::dbpasswd", ""); #aka user is already identified

    my $self = { 'database' => Finance::GeniusTrader::Conf::get("DB::csv::database"),
		 'dbname'   => Finance::GeniusTrader::Conf::get("DB::csv::dbname"),
    		 'dbhost'   => Finance::GeniusTrader::Conf::get("DB::csv::dbhost"), 
		 'dbuser'   => Finance::GeniusTrader::Conf::get("DB::csv::dbuser"), 
		 'dbpasswd' => Finance::GeniusTrader::Conf::get("DB::csv::dbpasswd"), 
		 @_
		};

    if ( $self->{'database'} eq "CSV" ) {
      Finance::GeniusTrader::Conf::default("DB::csv::connectstring", "DBI:CSV:f_dir=" . $self->{'dbname'} . ";csv_sep_char=\t" );
    } else {
      my $addstring = "";
      if ($self->{'dbhost'}) {
	$addstring .= ";host=" . $self->{'dbhost'};
      }
      Finance::GeniusTrader::Conf::default("DB::csv::connectstring", "DBI:" . $self->{'database'} . 
			":database=" . $self->{'dbname'} . $addstring );
    }
		
    my $connect_string = Finance::GeniusTrader::Conf::get("DB::csv::connectstring");
    $self->{'_dbh'} = DBI->connect($connect_string, $self->{'dbuser'},
    		$self->{'dbpasswd'}) or die "Couldn't connect to database !\n";

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


=item C<< $db->init_table($code) >>

Creates the table of stock $code.

=cut
sub init_table {
    my ($self, $code) = @_;

    # If we use a CVS-Database, create the directory
    if ( $self->{'database'} eq "CSV" ) {
        my $DB_DIR = $self->{'dbname'};
        if (! -d $DB_DIR) {
	    mkdir($DB_DIR, 0755) || 
		die "Could not create directory $DB_DIR.";
        }
    }

    $self->{'_dbh'}->do("
    CREATE TABLE PRICES_$code (
        open   REAL,
        close  REAL,
        high   REAL,
        low    REAL,
        volume REAL,
        date   CHAR(10)
    )") or die "Could not create table PRICES_$code.";
}

=item C<< $db->init_add_info() >>

Creates the addinfo-table.

=cut
sub init_add_info {
    my $self = shift;

    # If we use a CVS-Database, create the directory
    if ( $self->{'database'} eq "CSV" ) {
        my $DB_DIR = $self->{'dbname'};
        if (! -d $DB_DIR) {
	    mkdir($DB_DIR, 0755) || 
		die "Could not create directory $DB_DIR.";
        }
    }

    $self->{'_dbh'}->do(<<'EOT') or die "Could not create table addinfo.";
    CREATE TABLE addinfo (
        info   CHAR(60),
        code   CHAR(15),
        date   CHAR(10),
        value  CHAR(100)
    )
EOT
}

=item C<< $db->init_add_info() >>

Creates the shares-table.

=cut
sub init_shares {
    my $self = shift;

    # If we use a CVS-Database, create the directory
    if ( $self->{'database'} eq "CSV" ) {
        my $DB_DIR = $self->{'dbname'};
        if (! -d $DB_DIR) {
	    mkdir($DB_DIR, 0755) || 
		die "Could not create directory $DB_DIR.";
        }
    }

    $self->{'_dbh'}->do(<<'EOT') or die "Could not create table addinfo.";
    CREATE TABLE shares (
        name   CHAR(100),
        code   CHAR(15)
    )
EOT
}

=item C<< $db->get_prices($code) >>

Returns a Finance::GeniusTrader::Prices object containing all known prices for the symbol $code.

=cut
sub get_prices {
    return get_last_prices(@_, -1);
}

=item C<< $db->get_last_prices($code, $limit) >>

Returns a Finance::GeniusTrader::Prices object containing the $limit last known prices for
the symbol $code.

=cut
sub get_last_prices {
    my ($self, $code, $limit) = @_;

    my $q = Finance::GeniusTrader::Prices->new($limit);
    $q->set_timeframe($DAY);

    my $sql = qq{ SELECT open, high, low, close, volume, date
    		  FROM PRICES_$code ORDER BY date DESC };
    if ($limit > 0) {
	$sql .= "LIMIT $limit";
    }

    my $ref = $self->{'_dbh'}->selectall_arrayref( $sql )
      or die $self->{'_dbh'}->errstr();

    my @prices = @{$ref};
    @prices = sort { $b->[5] cmp $a->[5] } @prices;

    my $res;
    foreach $res (reverse @prices)
    {
	$q->add_prices($res);
    }
    return $q;
}


# Now some basic management functions
# ###################################

=item C<< $db->insert($code) >>

Creates the table of stock $code.

=cut
sub insert {
    my $self = shift;
    my %values = @_;
    no strict "refs";

    # Exit if the Primary Key is not defined
    my @INDEX_FIELDS = qw/date/;
    foreach my $f (@INDEX_FIELDS) {
	return if ( !defined($values{$f}) );
    }

    my @names = ();
    my @vals  = ();
    while ( my ($key, $value) = each %values) {
	if ($key ne 'code') {
	    push @names, $key;
	    push @vals, $value;
	}
    }

    for (my $i=0; $i<=$#vals; $i++) {
	return if ( $vals[$i] !~ /^[\d\.-]+$/ ); # Somtimes a "n/a" occurs
	$vals[$i] = "'" . $vals[$i] . "'";
    }

    $self->{'_dbh'}->do( "INSERT INTO PRICES_" .$values{'code'} . " (" . join(", ", @names) . 
	      ") VALUES (" . join(", ", @vals) . ")" ) 
	or warn $self->{'_dbh'}->errstr();

}

=item C<< $db->get( parameters ) >>

Get the datasets where all the parameters match

=cut
sub get {
    my $self = shift;
    no strict "refs";
    my %values = @_;

    my @wheres = ();
    while ( my ($key, $value) = each %values) {
	push @wheres, "$key = '$value'" if ($key ne 'code');
    }
    my $where = join(" AND ", @wheres);
    $where = "WHERE " . $where if ( $where ne "" );

    my $ref = $self->{'_dbh'}->selectall_arrayref( "SELECT open, high, low, close, volume, date FROM PRICES_" .$values{'code'} . " " . $where );
#	or die $self->{'_dbh'}->errstr();

    return @{$ref};
}

=item C<< $db->available( $code, $date ) >>

Returns 1 if a dataset for the corresponding day is available.

=cut
sub available {
    my ($self, $code, $date) = @_;
    my @data = $self->get( "date" => $date, "code" => $code );
    my $res = ( $#data >= 0 ) ? 1 : 0;
    return $res;
}

=item C<< $db->get( parameters ) >>

Delete the datasets where all the parameters match

=cut
sub del {
    my $self = shift;
    my %values = @_;
    no strict "refs";

    my @wheres = ();
    while ( my ($key, $value) = each %values) {
	push @wheres, "$key = '$value'" if ($key ne 'code');
    }
    my $where = join(" AND ", @wheres);
    $where = "WHERE " . $where if ( $where ne "" );

    $self->{'_dbh'}->do( "DELETE FROM PRICES_" .$values{'code'} . " " . $where )
	or die $self->{'_dbh'}->errstr();

}

=item C<< $db->edit( parameters ) >>

Edit the dataset where the date and the code matches

=cut
sub edit {
    my $self = shift;
    my %values = @_;
    no strict "refs";
    my @INDEX_FIELDS = qw/date/;

    # Define what field to update
    my @wheres = ();
    foreach my $f (@INDEX_FIELDS) {
	if ( defined($values{$f}) ) {
	    push @wheres, "$f = '" . $values{$f} . "'";
	    delete($values{$f});
	}
    }
    my $where = join(" AND ", @wheres);
    $where = "WHERE " . $where if ( $where ne "" );

    return if ( $where eq "" );

    # What is to be updated?
    my @sets = ();
    while ( my ($key, $value) = each %values) {
	push @sets, "$key = '$value' " if ($key ne 'code');
    }
    my $set = "SET " . join(", ", @sets);

    my $ref = $self->{'_dbh'}->do( "UPDATE PRICES_" .$values{'code'} . " " . $set . $where )
	or die $self->{'_dbh'}->errstr();

}

=item C<< $db->table_exists($code) >>

Test if a table for stock $code already exists

=cut
sub table_exists {
  my $self = shift;
  my $code = shift;
  my $test = $self->get( "code" => $code );
  my $ret = 0;
  $ret = 1 if ( defined($test) );
  return ( $ret );
}


# Management of shares (code, name)
# #################################

=item C<< $db->get_db_name($code) >>

Returns the name of the stock designated by $code.

=cut
sub get_db_name {
    my ($self, $code) = @_;
    my $sql = "SELECT name FROM shares WHERE code = '$code'";
    my $sth = $self->{'_dbh'}->prepare($sql) || die $self->{'_dbh'}->errstr;
    $sth->execute(); # || warn $self->{'_dbh'}->errstr;
    my $res = $sth->fetchrow_arrayref;
    $res->[0] =~ s/^\s*//s;
    $res->[0] =~ s/\s*$//s;
    return $res->[0];
}

=item C<< $db->get_db_code($name) >>

Returns the code of the stock designated by $name.

=cut
sub get_db_code {
    my ($self, $name) = @_;
    my $sql = "SELECT code, name FROM shares";
    my $ref = $self->{'_dbh'}->selectall_arrayref( $sql )
      or die $self->{'_dbh'}->errstr();
    my @codes = @{$ref};
    my $res = $name;
    foreach my $code (@codes)
    {
        $res = $code->[0] if ($code->[1] =~ /$name/i);
    }
    $res =~ s/^\s*//s;
    $res =~ s/\s*$//s;
    return $res;
}


# Management of additional Informations
# #####################################

=item C<< $db->get_add_info($code,$date) >>

Returns an additional information about the stock

=cut
sub get_add_info {
    my ($self, $info, $code, $date) = @_;

    my $sql = "SELECT value FROM addinfo WHERE info = '$info' AND code = '$code'";
    $sql .= " AND date = '$date'" if (defined($date));

    my $sth = $self->{'_dbh'}->prepare($sql) || die $self->{'_dbh'}->errstr;
    $sth->execute() || die $self->{'_dbh'}->errstr;
    my $res = $sth->fetchrow_arrayref;
    $res->[0] =~ s/^\s*//;
    $res->[0] =~ s/\s*$//;
    return $res->[0];
}

=item C<< $db->get_add_info($code,$date) >>

Returns an additional information about the stock

=cut
sub set_db_name {
    my ($self, $code, $name) = @_;

    # Check if the dataset is available
    my $res = $self->get_db_name($code);

    if ( defined($res) ) {
	my $sql = "UPDATE shares SET name = '$name' WHERE code = '$code'";
	my $sth = $self->{'_dbh'}->do($sql) || die $self->{'_dbh'}->errstr;
    } else {
	my $sql = "INSERT INTO shares (code, name) VALUES ('$code', '$name')";
	my $sth = $self->{'_dbh'}->do($sql) || die $self->{'_dbh'}->errstr;
    }
}


=item C<< $db->set_add_info($value, $info, $code, $date) >>

Set an additional information about the stock

=cut
sub set_add_info {
    my ($self, $value, $info, $code, $date) = @_;

    # Check if the dataset is available
    my $res = $self->get_add_info($info, $code, $date);

    if ( defined($res) ) {
	my $sql = "UPDATE addinfo SET value = '$value' WHERE info = '$info' AND code = '$code'";
	$sql .= " AND date = '$date'" if (defined($date));
	my $sth = $self->{'_dbh'}->do($sql) || die $self->{'_dbh'}->errstr;
    } else {
	$date = "-" if ( !defined($date) );
	my $sql = "INSERT INTO addinfo (info, code, date, value) VALUES ('$info', '$code', '$date', '$value')";
	my $sth = $self->{'_dbh'}->do($sql) || die $self->{'_dbh'}->errstr;
    }

}


# Communication with other databases/sources
# ##########################################

=item C<< $db->update_from_source($code) >>

This function is getting the actual information from the web.

=cut
sub update_from_source {
    my $self = shift;
    my ($source, $code) = @_;

    my $newtable = 0;
    if ( !$self->table_exists( $code ) ) {
      $self->init_table( $code );
      $newtable = 1;
    }

    my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime;
    my $today = sprintf("%04d-%02d-%02d", $y + 1900, $m + 1, $d);

    # Return if the current day is already available
    return if ( $self->available($code, $today) == 1 );

    # Check for the update-cycle
    Finance::GeniusTrader::Conf::default("DB::Source::$source::UpdateCycle", "12"); # 12h
    my $update = Finance::GeniusTrader::Conf::get("DB::Source::$source::UpdateCycle");
    my $lastupdate = $self->get_add_info( "Update_$source", $code );
    my $now = timelocal($sec, $min, $hour, $d, $m, $y);
    $update = $update * 60 * 60; # --> seconds

    print ">>" . $lastupdate . "<<\n";

    if ( $lastupdate eq "" || ( $lastupdate + $update < $now  ) ) {
	my $prices = $self->get_last_prices($code, 1);
	my $latest_date = $prices->find_nearest_date($today);

#	return if ( !defined($prices->at_date($latest_date)) );
	my $last_date;
	if ( !defined($prices->at_date($latest_date)) ) {
	  $last_date = "1960-01-01";
	} else {
	  $last_date = $prices->at_date($latest_date)->[$DATE];
	}
	# Decrement the month
	my @last_dat = split /-/, $last_date;
	#$last_dat[1]--;
	$last_date = join("-", @last_dat);
	print $last_date . " to " . $today . "\n";
	my @data = ();
	my $getstring = "use Finance::GeniusTrader::DB::$source; my \$s = Finance::GeniusTrader::DB::$source->new();
                         \@data = \$s->get_price_interval('$code', '$last_date', '$today');";

	eval $getstring;
	if ($@) {
	    warn "$@ : $getstring";
	    return;
	}
	
	for (my $d=0; $d <= $#data; $d++) {

	  if ( $self->available($code, $data[$d][5]) == 1 ) {
	    $self->edit( code   => $code, 
			 date   => $data[$d][5], 
			 open   => $data[$d][0],
			 high   => $data[$d][1],
			 low    => $data[$d][2],
			 close  => $data[$d][3],
			 volume => $data[$d][4]
		       );
	  } else {
	    $self->insert( code   => $code, 
			   date   => $data[$d][5], 
			   open   => $data[$d][0],
			   high   => $data[$d][1],
			   low    => $data[$d][2],
			   close  => $data[$d][3],
			   volume => $data[$d][4]
			 );
	  }
	}

    }

    # New update-information
    $self->set_add_info("$now" ,"Update_$source", $code);

}

=item C<< $db->get_all_prices($code) >>

Dummy function. Need to define a clear interface for the exchange.

=cut
sub get_all_prices {
  my $self = shift;
  my $code = shift;
  return ( $self->get( code => $code) );
}

=item C<< $db->merge_from_source($source, $code) >>

Merges the content of an other database/source into the current db. 
This needs to be updated with a "ranking" algorithm. 

=cut
sub merge_from_source {
  my $self = shift;
  my ($source, $code) = @_;

  # Create the table ?!?!
  $self->init_table( $code ) if ($self->table_exists("$code") == 0); 

  my @data = ();
  my $getstring = "use Finance::GeniusTrader::DB::$source; my \$s = Finance::GeniusTrader::DB::$source->new();
                     \@data = \$s->get_all_prices('$code');\$s->disconnect();";

  eval $getstring;
  if ($@) {
    warn "$@ : $getstring";
    return;
  }

  for (my $d=0; $d <= $#data; $d++) {

    my ($open, $high, $low, $close, $volume, $date) = ($data[$d][0], $data[$d][1], $data[$d][2], $data[$d][3], $data[$d][4], $data[$d][5]);

    #print $date . "\n";
    #print "NEW: " . join( "\t", ($open, $high, $low, $close, $volume, $date) ) . "\n";

    my @data2 = ( [] );
    if ( $self->available($code, $date) == 1 ) {

      @data2 = $self->get( code => $code, date => $date );
      #print  "OLD: " . join( "\t", @{$data2[0]} ) . "\n";

      if ( $open != $data2[0][0] ) {
	if ( $open - $data2[0][0] <= 0.01 ) {
	  $open = $data2[0][0];
	} else {
	  print STDERR "  $code $date differs : OPEN   $open != " . $data2[0][0] . "\n" 
	}
      }
      if ( $high != $data2[0][1] ) {
	if ( $high - $data2[0][1] <= 0.01 ) {
	  $high = $data2[0][1];
	} else {
	  print STDERR "  $code $date differs : HIGH   $high != " . $data2[0][1] . "\n" 
	}
      }
      if ( $low != $data2[0][2] ) {
	if ( $low - $data2[0][2] <= 0.01 ) {
	  $low = $data2[0][2];
	} else {
	  print STDERR "  $code $date differs : LOW   $low != " . $data2[0][2] . "\n" 
	}
      }
      if ( $close != $data2[0][3] ) {
	if ( $close - $data2[0][3] <= 0.01 ) {
	  $close = $data2[0][3];
	} else {
	  print STDERR "  $code $date differs : CLOSE   $close != " . $data2[0][3] . "\n" 
	}
      }
      if ( $volume != $data2[0][4] ) {
	if ( $volume == 0 ) {
	  $volume = $data2[0][4];
	} elsif ( $data2[0][4] == 0 ) {
	} else {
	  print STDERR "  $code $date differs : VOLUME   $volume != " . $data2[0][4] . "\n" unless (abs($volume != $data2[0][4]) <= 1);
	}
      }

      $self->edit( code   => $code,
		   date   => $date,
		   open   => $open,
		   high   => $high,
		   low    => $low,
		   close  => $close,
		   volume => $volume
		 );

    } else {
      $self->insert( code   => $code,
		     date   => $date,
		     open   => $open,
		     high   => $high,
		     low    => $low,
		     close  => $close,
		     volume => $volume
		   );

    }

    ##print "x" x 60 . "\n";

  }

}

=item C<< $db->merge_all_from_source($source) >>

Merges the content of all shares in an other database/source into the current db. 

=cut
sub merge_all_from_source {
  my $self = shift;
  my ($source) = @_;
  my $ref = $self->{'_dbh'}->selectall_arrayref( "SELECT code FROM shares" );
  my @codes = @{$ref};
  for (my $i=0; $i<=$#codes; $i++) {
      $codes[$i][0] =~ s/ *$//;
      print $codes[$i][0] . "\n";
      $self->merge_from_source($source, $codes[$i][0]);
  }
}

=item C<< $db->update_all_from_source($source) >>

Updates all shares from a source. 

=cut
sub update_all_from_source {
  my $self = shift;
  my ($source) = @_;
  my $ref = $self->{'_dbh'}->selectall_arrayref( "SELECT code FROM shares" );
  my @codes = @{$ref};
  for (my $i=0; $i<=$#codes; $i++) {
      $codes[$i][0] =~ s/ *$//;
      print $codes[$i][0] . "\n";
      $self->update_from_source($source, $codes[$i][0]);
  }
}

=pod

=back

=cut
1;
