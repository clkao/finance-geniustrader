package GT::DB::Text;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# baseline  9 Jul 2005  5304 bytes
# $Id$

use strict;
our @ISA = qw(GT::DB);

use GT::DB;
use GT::Prices;
use GT::Conf;
use GT::DateTime;

=head1 DB::Text access module

=head2 Overview

This database access module enable you to work with a full directory of
text files.

=head2 Configuration

You must set the GT::Text::directory configuration item to tell where
the quotes are usually stored.

You can optionally set the GT::Text::options configuration item to tell GT
how to read the Text file:

DB::module Text

DB::Text::directory  /home/projects/geniustrader/database

                     +- "," - The field separator
                     |
                     |    +- 2 - The Date format. Valid values are:
                     |    |      0 - YYYY-MM-DD Format (default gt format)
                     |    |      1 - US Format (mm/dd/yyyy)
                     |    |      2 - European Format (dd/mm/yyyy)
                     |    |
                     |    |      +- ".csv" - The extension of the data files
                     |    |      |
                     |    |      |        +- column data and column number 0 ... n-1
                     |    |      |        |
DB::Text::options ( "," , 2 , ".csv" , ('date' => 0, 'open' => 1, 'high' => 2, 'low' => 3, 'close' => 4, 'volume' => 5, 'Adj. Close*' => 6) )

The remaining fields represent the position of each data field inside each row of the data file

For the sample data files 13000.txt, etc you must set DB::Text::options in your
options file (.gt/options) to

                      V must be the tab character
 DB::Text::options ( "	" , 0 , ".txt" , ("date" => 5, "open" => 0, "high" => 1, "low" => 2, "close" => 3, "volume" => 4, "Adj. Close*" => 3) )
or you can use
 DB::Text::options ( "\t" , 0 , ".txt" , ("date" => 5, "open" => 0, "high" => 1, "low" => 2, "close" => 3, "volume" => 4, "Adj. Close*" => 3) )

if the The field separator is longer than 1 character (but not "\t") a warning will be issued

=head2 new()

Create a new DB object used to retry quotes from a directory
full of text files containing prices.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { "directory" => GT::Conf::get("DB::Text::directory")};

    GT::Conf::default('DB::Text::options', '( "," , 2 , ".csv" , ("date" => 0, "open" => 1, "high" => 2, "low" => 3, "close" => 4, "volume" => 5, "Adj. Close*" => 6) )');

    my $options=GT::Conf::get("DB::Text::options");
#( "\t" , 2 , ".txt" , ( 'open' , 0, 'high' , 1, 'low' , 2, 'close' , 3, %'volume' , 4, 'date' , 5 ) )
    if ( $options =~ /^\(\s+\"(.+)\"\s+,\s+(.+)\s+,\s+\"(.+)\"\s+,\s+(\(.+)\s+\)$/ )
    {
	    my $mark=$1;
            if ( $mark != "\t" && length($mark) > 1 ) {
               warn "GT::Text::new: warning: the separator value \"$mark\" is more than one character\n"
            }
	    my $date_format=$2;
	    my $extention=$3;
	    my $fields=$4;

	    $self->{'mark'} = $mark;
	    $self->{'date_format'} = $date_format;
	    $self->{'extention'} = $extention;

        #( 'date' => 0, 'open' => 1, 'high' => 2, 'low' => 3, 'close' => 4, 'volume' => 5, 'Adj. Close*' => 6)
        #( 'open' => 0, 'high' => 1, 'low' => 2, 'close' => 3, 'volume' => 4, 'date' => 5 ) )
        if ( $fields =~/^.*(,|\()\s*'open'\s*=>\s*(\d+)\s*(,|\)).*$/  )
	    {	$self->{'open'} = $2;	}

    	if ( $fields =~/^.*(,|\()\s*'high'\s*=>\s*(\d+)\s*(,|\)).*$/ )
    	{	$self->{'high'} = $2;	}

    	if ( $fields =~/^.*(,|\()\s*'low'\s*=>\s*(\d+)\s*(,|\)).*$/ )
    	{	$self->{'low'} = $2;	}

    	if ( $fields =~/^.*(,|\()\s*'close'\s*=>\s*(\d+)\s*(,|\)).*$/ )
    	{	$self->{'close'} = $2;	}

    	if ( $fields =~/^.*(,|\()\s*'volume'\s*=>\s*(\d+)\s*(,|\)).*$/ )
    	{	$self->{'volume'} = $2;	}

    	if ( $fields =~/^.*(,|\()\s*'date'\s*=>\s*(\d+)\s*(,|\)).*$/ )
    	{	$self->{'date'} = $2;	}
    }
    return bless $self, $class;
}

=head2 $db->disconnect

Disconnects from the database.

=cut

sub disconnect {
    my $self = shift;
}

=head2 $db->set_directory("/new/directory")

Indicate the directory containing all the text files.

=cut

sub set_directory {
    my ($self, $dir) = @_;
    $self->{'directory'} = $dir;
}


=head2 $db->set_options($mark, $date_format, $extention, %fields)

Set up all available options required to load text files.

By default :
 - Mark is a tabulation ("\t")

 - Date Format
    0 : GeniusTrader Date Format (YYYY-MM-DD)
    1 : US sort of Date Format (mm/dd/yyyy)
    2 : EU sort of Date Format (dd/mm/yyyy)

 - Extention
    ".txt"

 - Fields Map
     %fields = ('open' => 0, 'high' => 1, 'low' => 2, 'close' => 3,
     %'volume' => 4, 'date' => 5);

=cut

sub set_options {
    my ($self, $mark, $date_format, $extention, %fields) = @_;

    if ($mark) { $self->{'mark'} = $mark; }
    if ($date_format) {$self->{'date_format'} = $date_format; }
    if ($extention) { $self->{'extention'} = $extention; }
    if (%fields) {
	$self->{'open'} = $fields{'open'};
	$self->{'high'} = $fields{'high'};
	$self->{'low'} = $fields{'low'};
	$self->{'close'} = $fields{'close'};
	$self->{'volume'} = $fields{'volume'};
	$self->{'date'} = $fields{'date'};
    }
}

=head2 $db->get_prices($code, $timeframe)

Returns a GT::Prices object containing all known prices for the symbol $code.

=cut

sub get_prices {
    my ($self, $code, $timeframe) = @_;
    $timeframe = $DAY unless ($timeframe);
    die "Intraday support not implemented in DB::Text" if ($timeframe < $DAY);
    return GT::Prices->new() if ($timeframe > $DAY);

    my $prices = GT::Prices->new;
    $prices->set_timeframe($timeframe);

    if (!exists($self->{'mark'})) { $self->{'mark'} = "\t"; }
    if (!exists($self->{'date_format'})) { $self->{'date_format'} = 0; }
    if (!exists($self->{'extention'})) { $self->{'extention'} = ".txt"; }
    if (!exists($self->{'open'})) { $self->{'open'} = 0; }
    if (!exists($self->{'high'})) { $self->{'high'} = 1; }
    if (!exists($self->{'low'})) { $self->{'low'} = 2; }
    if (!exists($self->{'close'})) { $self->{'close'} = 3; }
    if (!exists($self->{'volume'})) { $self->{'volume'} = 4; }
    if (!exists($self->{'date'})) { $self->{'date'} = 5;}

    my %fields = ('open' => $self->{'open'}, 'high' => $self->{'high'},
                  'low' => $self->{'low'}, 'close' => $self->{'close'},
		  'volume' => $self->{'volume'}, 'date' => $self->{'date'});

    $prices->loadtxt($self->{'directory'} . "/$code" . $self->{'extention'},
		     $self->{'mark'}, $self->{'date_format'},
		     %fields);
    return $prices;
}

=pod

=head2 $db->get_last_prices($code, $limit, $timeframe)

NOT SUPPORTED for text db.

Returns a GT::Prices object containing the $limit last known prices for
the symbol $code.

=cut
sub get_last_prices {
    my ($self, $code, $limit, $timeframe) = @_;

    return get_prices($self, $code, $timeframe) if ($limit==-1);
    die "get_last_prices not supported with text database\n";
}

sub has_code {
    my ($self, $code) = @_;
    my $file = ($self->{'directory'} . "/$code" . $self->{'extention'});
    if (-e $file) {
	return 1;
    }
    return 0;
}

1;
