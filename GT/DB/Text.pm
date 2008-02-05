package GT::DB::Text;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# new version joao costa circa nov 07

use strict;
our @ISA = qw(GT::DB);

use GT::DB;
use GT::Prices;
use GT::Conf;
use GT::DateTime;
use Date::Manip;

=head1 DB::Text access module

=head2 Overview

This database access module enable you to work with a full directory of
text files.

=head2 Configuration

All configuration items are required

DB::module Text

DB::text::directory  path where files are stored

DB::text::marker  string which delimits fields in each row of the data file

DB::text::file_extension  string to be appended to the code file name when 
searching the data file.  for instance, if the data file is called EURUSD.csv
this variable would have the value .csv

if you have data in different timeframes, for instance, EURUSD_hour.csv and
EURUSD_day.csv, use the following value for this directive:

DB::text::file_extension  _$timeframe.csv

DB::text::fields::datetime  Column index where to find the period datetime field.
Indexes are 0 based.  For the particular case of datetime, can contain
multiple indexes, useful when date and time are separate columns in the data
file.  The date time format is anything that can be understood by Date::Manip.
A typical example would be YYYY-MM-DD HH:NN:SS


DB::text::fields::open Column index where to find the period open field.
Indexes are 0 based.  

DB::text::fields::low Column index where to find the period low field.
Indexes are 0 based.  

DB::text::fields::high Column index where to find the period high field.
Indexes are 0 based.  

DB::text::fields::close Column index where to find the period close field.
Indexes are 0 based.  

DB::text::fields::volume Column index where to find the period volume field.
Indexes are 0 based.  


=head2 new()

Create a new DB object used to retry quotes from a directory
full of text files containing prices.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { "directory" => GT::Conf::get("DB::Text::directory")};

    GT::Conf::default('DB::Text::marker', "\t");
    GT::Conf::default('DB::Text::file_extension', '.txt');
    GT::Conf::default('DB::Text::fields::datetime', '5');
    GT::Conf::default('DB::Text::fields::open', '0');
    GT::Conf::default('DB::Text::fields::low', '2');
    GT::Conf::default('DB::Text::fields::high', '1');
    GT::Conf::default('DB::Text::fields::close', '3');
    GT::Conf::default('DB::Text::fields::volume', '4');

	$self->{'mark'} = GT::Conf::get('DB::Text::marker');
	$self->{'extension'} = GT::Conf::get('DB::Text::file_extension');
	$self->{'datetime'} = GT::Conf::get('DB::Text::fields::datetime');
	$self->{'open'} = GT::Conf::get('DB::Text::fields::open');
	$self->{'low'} = GT::Conf::get('DB::Text::fields::low');
	$self->{'high'} = GT::Conf::get('DB::Text::fields::high');
	$self->{'close'} = GT::Conf::get('DB::Text::fields::close');
	$self->{'volume'} = GT::Conf::get('DB::Text::fields::volume');

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

=head2 $db->get_prices($code, $timeframe)

Returns a GT::Prices object containing all known prices for the symbol $code.

=cut

sub get_prices {
    my ($self, $code, $timeframe) = @_;
    $timeframe = $DAY unless ($timeframe);

    my @datetime_fields = split(',',$self->{'datetime'});
	my $datetime_fields_count = scalar(@datetime_fields);

    my $prices = GT::Prices->new;
    $prices->set_timeframe($timeframe);

	my $extension = $self->{'extension'};
	my $tfname = GT::DateTime::name_of_timeframe($timeframe);
	$extension =~ s/\$timeframe/$tfname/g;

	my $file = $self->{'directory'} . "/$code" . $extension;

    open(FILE, "<$file") || (warn "Can't open $file: $!\n" and return GT::Prices->new());

    my ($open, $high, $low, $close, $volume, $date);
    my ($year, $month, $day);


	#TODO
	#Date::Manip requires this to be defined
	#there probably is a better way of doing this
	#rather than defining it here, but it works
	#for now
	$ENV{'TZ'} = 'GMT' unless(defined($ENV{'TZ'})); 

    # Process each line in $file...
    while (defined($_=<FILE>))
    {
		next if (/^[#<]/); #Skip comments and METASTOCK ascii file header
	    # Get and split the line with $mark
	    chomp;
	    my @line = split($self->{'mark'});

	    # Get and swap all necessary fields according to the fields map
	    $open = $line[$self->{'open'}];
	    $high = $line[$self->{'high'}];
	    $low = $line[$self->{'low'}];
	    $close = $line[$self->{'close'}];
	    $volume = $line[$self->{'volume'}] or $volume = 0; #some datasets don't include volume
		my $datetime=$line[$datetime_fields[0]];
		for (my $i=1; $i<$datetime_fields_count;$i++) {
			$datetime .= ' '.$line[$datetime_fields[$i]];
		}
		$date = &UnixDate($datetime, '%Y-%m-%d %H:%M:%S');

	    # Add all data within the GT::Prices object
	    $prices->add_prices([ $open, $high, $low, $close, $volume, $date ]);
    }
    close FILE;

    return $prices;
}

=pod

=head2 $db->get_last_prices($code, $limit, $timeframe)

Returns a GT::Prices object containing the $limit last known prices for
the symbol $code.

=cut
sub get_last_prices {
    my ($self, $code, $limit, $timeframe) = @_;

	warn "$limit parameter ignored in DB::Text::get_last_prices. loading entire dataset." if ($limit > -1);
    return get_prices($self, $code, $timeframe,-1);
}

sub has_code {
    my ($self, $code) = @_;
	my $extension = $self->{'extension'};
	$extension =~ s/\$timeframe/\.\*/g;
	my $file_exists = 0;
    my $file_pattern = "$code$extension";

	if ($extension =~ /\*/) {
	  eval "use File::Find;";
	  find (  sub {	$file_exists = 1 if ($_ =~ /$file_pattern/);  },$self->{'directory'});
	} else {
      $file_exists = 1 if (-e $file_pattern);
	}

	return $file_exists;
}

1;
