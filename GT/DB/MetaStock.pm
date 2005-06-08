package GT::DB::MetaStock;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use Date::Calc qw(Decode_Date_EU);

use GT::DB;
use GT::Prices;
use GT::DateTime;

=head1 DB::MetaStock access module

=head2 Overview

The MetaStock access module is able to retrieve quotes from almost any type of MetaStock/Computrac database.

=head2 Note

This module simply call the software "MetaStockReader" to get quotes, with a directory and a symbol as main parameters. Please refer to it's source if you want to learn more about it.

=head2 Configuration

You can indicate the directory which contains the MetaStock database
by setting the DB::metastock::directory configuration item. You can
also set DB::metastock::program to indicate where the MetaStockReader.

=head2 new()

Create a new DB object used to retry quotes from a MetaStock database.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    GT::Conf::default("DB::metastock::directory", "");
    GT::Conf::default("DB::metastock::program", 
		      "/bourse/tools/MetaStockReader");

    my $self = { "directory" => GT::Conf::get("DB::metastock::directory"),
		 "program"   => GT::Conf::get("DB::metastock::program") };
		
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
    my ($self, $directory) = @_;
    $self->{'directory'} = $directory;
}

=head2 $db->get_prices($code, $timeframe)

Returns a GT::Prices object containing all known prices for the symbol $code.

=cut
sub get_prices {
    my ($self, $code, $timeframe) = @_;
	$timeframe = $DAY unless ($timeframe);
    die "Intraday support not implemented in DB::MetaStock" if ($timeframe < $DAY);
    return GT::Prices->new() if ($timeframe > $DAY);

    my ($open, $high, $low, $close, $volume, $date, $time);
    my ($year, $month, $day);
    my %fields;
    my $position = 0;
    
    # Launch MetaStockReader with the correct arguments
    # in order to get all quotes for the specified symbol
    my @results = `$self->{'program'} -r $self->{'directory'} $code`;
 
    my $prices = GT::Prices->new();
    $prices->set_timeframe($timeframe);
    
    foreach (@results) {

	if ($position eq 0) {
	    
	    # Get HEADER and set up %fields according to the fields map
	    # usually : date [time] [open] high low close volume
	    
	    my @header = split(/\t/, $results[0]);
	    my $i = 0;
	    
	    foreach (@header) {

		my $field = $header[$i];
		$field =~ s/\n//;

		if ($field eq "Open") {
		    $fields{'open'} = $i;
		}
		if ($field eq "High") {
		    $fields{'high'} = $i;
		}
		if ($field eq "Low") {
		    $fields{'low'} = $i;
                }
                if ($field eq "Close") {
                    $fields{'close'} = $i;
                }
                if ($field eq "Volume") {
                    $fields{'volume'} = $i;
                }
                if ($field eq "Date") {
                    $fields{'date'} = $i;
                }
		if ($field eq "Time") {
                    $fields{'time'} = $i;
                }
		$i++;
	    }
	    
	} else {

	    # Get and split each line with a tabulation
	    my @line = split(/\t/, $results[$position]);

	    # Get and swap all necessary fields according to the header
	    $open = $line[$fields{'open'}];
            $high = $line[$fields{'high'}];
            $low = $line[$fields{'low'}];
            $close = $line[$fields{'close'}];
	    $volume = $line[$fields{'volume'}];
            $date = $line[$fields{'date'}];
	    if ($fields{'time'}) {
		$time = $line[$fields{'time'}];
	    }

	    # Decode MetaStock date format to something more usefull
	    ($year, $month, $day) = Decode_Date_EU($date); 
	    
	    # And convert it to GeniusTrader standard format
	    $date = $year . "-" . $month . "-" .$day;
	    if ($fields{'time'}) {
		$date .= "-" . $time;
	    }
	    
	    # Add all data within the GT::Prices object
	    $prices->add_prices([ $open, $high, $low, $close, $volume, $date ]);
	    
	}
	$position++;
    }
    return $prices;
}

=head2 $db->get_last_prices($code, $limit, $timeframe)

NOT SUPPORTED for text db.

Returns a GT::Prices object containing the $limit last known prices for
the symbol $code.

=cut
sub get_last_prices {
    my ($self, $code, $limit, $timeframe) = @_;

    return get_prices($self, $code, $timeframe) if ($limit==-1);
    die "get_last_prices not yet supported with metastock database\n";
}

1;
