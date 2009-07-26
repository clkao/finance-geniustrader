package Finance::GeniusTrader::DB::Text;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# new version joao costa circa nov 07
# $Id$

use strict;
our @ISA = qw(Finance::GeniusTrader::DB);

use Finance::GeniusTrader::DB;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Conf;
use Finance::GeniusTrader::DateTime;

=head1 DB::Text access module

=head2 Overview

This database access module enable you to work with a full directory of
text files.

=head2 Configuration

Most configuration items have default values, to alter these defaults
you must indicate the configuration item and its value in your
$HOME/.gt/options file.

=over

=item DB::module	Text

Informs gt you are using the Text.pm module. This
configuration item is always required in your $HOME/.gt/options file.

=item DB::text::directory	path

where files are stored. This
configuration item is always required in your $HOME/.gt/options file.

=item DB::text::marker	string 

Delimits fields in each row of the data file.
The marker defaults to the tab character '\t'.

=item DB::text::header_lines	number

The number of header lines in your data file
that are to be skipped during processing. Lines with the either the
comment symbol '#' or the less than symbol '<' as the first character
do not need to be included in this value.. The header_lines default value is 0.

=item DB::text::file_extension	string

To be appended to the code file name when 
searching the data file.  For instance, if the data file is called EURUSD.csv
this variable would have the value '.csv' (without the quotes).

The default file_extension is '.txt'.

if you have data in different timeframes, for instance, EURUSD_hour.csv and
EURUSD_day.csv, use the following value for this directive:

=item DB::text::file_extension	_$timeframe.csv

=item DB::text::format                0|1|2|3 (default is 3)
The format of the date/time string. Valid values are: 
0 - yyyy-mm-dd hh:nn:ss (the time string is optional)
1 - US Format (month before day, any format understood by Date::Calc)
2 - European Format (day before month, any format understood by Date::Calc)
3 - Any format understood by Date::Manip

=item DB::text::fields::datetime	number

Column index where to find the period datetime
field. Indexes are 0 based.  For the particular case of datetime, can contain
multiple indexes, useful when date and time are separate columns in the data
file.  The date time format is anything that can be understood by Date::Manip.
A typical example would be YYYY-MM-DD HH:NN:SS. The default datetime index is 5.

=item DB::text::fields::open	number

Column index where to find the period open field.
Indexes are 0 based. The default open index is 0.

=item DB::text::fields::low	number

Column index where to find the period low field.
Indexes are 0 based. The default low index is 2. 

=item DB::text::fields::high	number

Column index where to find the period high field.
Indexes are 0 based. The default high index is 1.

=item DB::text::fields::close	number

Column index where to find the period close field.
Indexes are 0 based. The default close index is 3.

=item DB::text::fields::volume	number

Column index where to find the period volume field.
Indexes are 0 based. The default volume index is 4.


=head2 new()

Create a new DB object used to retrieve quotes from a directory
full of text files containing prices.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { "directory" => Finance::GeniusTrader::Conf::get("DB::Text::directory")};

    Finance::GeniusTrader::Conf::default('DB::Text::header_lines', '0');
    Finance::GeniusTrader::Conf::default('DB::Text::marker', "\t");
    Finance::GeniusTrader::Conf::default('DB::Text::file_extension', '.txt');
    Finance::GeniusTrader::Conf::default('DB::Text::format', '3');
    Finance::GeniusTrader::Conf::default('DB::Text::fields::datetime', '5');
    Finance::GeniusTrader::Conf::default('DB::Text::fields::open', '0');
    Finance::GeniusTrader::Conf::default('DB::Text::fields::low', '2');
    Finance::GeniusTrader::Conf::default('DB::Text::fields::high', '1');
    Finance::GeniusTrader::Conf::default('DB::Text::fields::close', '3');
    Finance::GeniusTrader::Conf::default('DB::Text::fields::volume', '4');

    $self->{'header_lines'} = Finance::GeniusTrader::Conf::get('DB::Text::header_lines');
    $self->{'mark'} = Finance::GeniusTrader::Conf::get('DB::Text::marker');
    $self->{'date_format'} = Finance::GeniusTrader::Conf::get('DB::Text::format');
    $self->{'extension'} = Finance::GeniusTrader::Conf::get('DB::Text::file_extension');
    $self->{'datetime'} = Finance::GeniusTrader::Conf::get('DB::Text::fields::datetime');
    $self->{'open'} = Finance::GeniusTrader::Conf::get('DB::Text::fields::open');
    $self->{'low'} = Finance::GeniusTrader::Conf::get('DB::Text::fields::low');
    $self->{'high'} = Finance::GeniusTrader::Conf::get('DB::Text::fields::high');
    $self->{'close'} = Finance::GeniusTrader::Conf::get('DB::Text::fields::close');
    $self->{'volume'} = Finance::GeniusTrader::Conf::get('DB::Text::fields::volume');

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

Returns a Finance::GeniusTrader::Prices object containing all known prices for the symbol $code.

=cut

sub get_prices {
    my ($self, $code, $timeframe) = @_;
    $timeframe = $DAY unless ($timeframe);

    my $prices = Finance::GeniusTrader::Prices->new;

    # WARNING: Can only load data that is in daily format or smaller
    # Trying to load weekly or monthly data will fail.
    return $prices if ($timeframe > $DAY);

    $prices->set_timeframe($timeframe);

    my %fields = ('open' => $self->{'open'}, 'high' => $self->{'high'},
                  'low' => $self->{'low'}, 'close' => $self->{'close'},
		  'volume' => $self->{'volume'}, 'date' => $self->{'datetime'});
    $self->{'fields'} = \%fields;

    my $extension = $self->{'extension'};
    my $tfname = Finance::GeniusTrader::DateTime::name_of_timeframe($timeframe);
    $extension =~ s/\$timeframe/$tfname/g;

    my $file = $self->{'directory'} . "/$code" . $extension;

    $prices->loadtxt($file, $self->{'mark'}, $self->{'date_format'},
		     $self->{'header_lines'}, %fields);
    return $prices;

}

=pod

=head2 $db->get_last_prices($code, $limit, $timeframe)

Returns a Finance::GeniusTrader::Prices object containing the $limit last known prices for
the symbol $code.

=cut
sub get_last_prices {
    my ($self, $code, $limit, $timeframe) = @_;

    ### warn "$limit parameter ignored in DB::Text::get_last_prices. loading entire dataset." if ($limit > -1);
    return get_prices($self, $code, $timeframe, -1);
}

sub has_code {
    my ($self, $code) = @_;
    my $extension = $self->{'extension'};
    $extension =~ s/\$timeframe/\.\*/g;
    my $file_exists = 0;
    my $file_pattern = $self->{'directory'} . "/$code$extension";

    if ($extension =~ /\*/) {
        eval "use File::Find;";
        find (  sub { $file_exists = 1 if ($_ =~ /$file_pattern/);  },$self->{'directory'});
    } else {
        $file_exists = 1 if (-e $file_pattern);
    }

    return $file_exists;
}

1;
