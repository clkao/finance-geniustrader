package GT::DB::Text;

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

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

You can set the GT::Text::directory configuration item to tell where
the quotes are usually stored.

=head2 new()

Create a new DB object used to retry quotes from a directory
full of text files containing prices.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { "directory" => GT::Conf::get("DB::Text::directory")};
    
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
    0 : GeniusTrader Date Format
    1 : US sort of Date Format
    2 : EU sort of Date Format
    
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

=head2 $db->get_prices($code)

Returns a GT::Prices object containing all known prices for the symbol $code.

=cut

sub get_prices {
    my ($self, $code) = @_;
    my $prices = GT::Prices->new;
    $prices->set_timeframe($DAY);

    if (!$self->{'mark'}) { $self->{'mark'} = "\t"; }
    if (!$self->{'date_format'}) { $self->{'date_format'} = 0; }
    if (!$self->{'extention'}) { $self->{'extention'} = ".txt"; }
    if (!$self->{'open'}) { $self->{'open'} = 0; }
    if (!$self->{'high'}) { $self->{'high'} = 1; }
    if (!$self->{'low'}) { $self->{'low'} = 2; }
    if (!$self->{'close'}) { $self->{'close'} = 3; }
    if (!$self->{'volume'}) { $self->{'volume'} = 4; }
    if (!$self->{'date'}) { $self->{'date'} = 5; }
 
    my %fields = ('open' => $self->{'open'}, 'high' => $self->{'high'},
                  'low' => $self->{'low'}, 'close' => $self->{'close'},
		  'volume' => $self->{'volume'}, 'date' => $self->{'date'});
    
    $prices->loadtxt($self->{'directory'} . "/$code" . $self->{'extention'}, 
		     $self->{'mark'}, $self->{'date_format'},
		     %fields);
    return $prices;
}

=pod 

=head2 $db->get_last_prices($code, $limit)

NOT SUPPORTED for text db.

Returns a GT::Prices object containing the $limit last known prices for
the symbol $code.

=cut
sub get_last_prices {
    my ($self, $code, $limit) = @_;

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