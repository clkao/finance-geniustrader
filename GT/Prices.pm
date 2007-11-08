package GT::Prices;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT $FIRST $OPEN $HIGH $LOW $CLOSE $LAST $VOLUME $DATE);

use Date::Calc qw(Decode_Date_US Decode_Date_EU Today);
#ALL#  use Log::Log4perl qw(:easy);
use GT::DateTime;
use GT::Serializable;

require Exporter;
@ISA = qw(Exporter GT::Serializable);
@EXPORT = qw($FIRST $OPEN $HIGH $LOW $LAST $CLOSE $VOLUME $DATE);

$FIRST = $OPEN = 0;
$HIGH = 1;
$LOW  = 2;
$LAST = $CLOSE = 3;
$VOLUME = 4;
$DATE = 5;

=head1 NAME

GT::Prices - A serie of prices

=head1 DESCRIPTION

GT::Prices stores all historic prices (open, high, low, close, volume, date).

=over

=item C<< my $p = GT::Prices->new() >>

Create an empty GT::Prices object.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { 'prices' => [], 'has_date' => '' };
    return bless $self, $class;
}

=item C<< $p->at(i) >>

Get the prices of the corresponding day. The indice can be obtained
from the dates by using $q->date('YYYY-MM-DD').

=item C<< $p->at_date('YYYY-MM-DD') >>

Get the prices of the corresponding date.

=cut
sub at {
    my ($self, $i) = @_;
    return $self->{'prices'}[$i];
}
sub at_date {
    my ($self, $date) = @_;
    return $self->at($self->date($date));
}

=item C<< $p->has_date('YYYY-MM-DD') >>

Return true if the object has prices for the corresponding date.

=cut
sub has_date {
    my ($self, $date) = @_;
	my $value = _binary_search($self->{'prices'}, $date);
	if (defined($value)) {
		#Often, a call to has_date preceds a call to date
		#so we might as well cache this value, so we won't need to call
		#the _binary_search function twice
		$self->{'has_date'} = $date;
		$self->{'date_pos'} = $value;
		return 1;
	}
    return 0;
}

=item C<< $p->date('YYYY-MM-DD') >>

Get the indice corresponding to the date 'YYYY-MM-DD'.

=cut
sub date {
    my ($self, $date) = @_;
	return $self->{'date_pos'} if ($self->{'has_date'} eq $date);
    return _binary_search($self->{'prices'}, $date);
}

=item C<< $p->add_prices_array([@price_array]) >>

=cut
sub add_prices_array {
    my ($self, @prices) = @_;
    push @{$self->{'prices'}}, @prices;
}

=item C<< $p->add_prices([$open, $high, $low, $close, $volume, $date]) >>

=cut
sub add_prices {
    my ($self, $prices) = @_;
    push @{$self->{'prices'}}, $prices;
}

=item C<< $p->count() >>

Get the number of prices availables.

=cut
sub count {
    return scalar(@{shift->{'prices'}});
}

=item C<< $p->set_timeframe($timeframe) >>

=item C<< $p->timeframe() >>

Defines the time frame used for the prices. It's one of the value exported
by GT::DateTime;

=cut
sub set_timeframe { $_[0]->{'timeframe'} = $_[1] }
sub timeframe { return $_[0]->{'timeframe'} }

=item C<< $p->sort() >>

Sort the prices by date.

=cut
sub sort {
    my ($self) = @_;
    my @prices = sort { 
	GT::DateTime::map_date_to_time($self->timeframe, $a->[$DATE]) <=>
	GT::DateTime::map_date_to_time($self->timeframe, $b->[$DATE])
    } @{$self->{'prices'}};
    $self->{'prices'} = \@prices;
}

=item C<< $p->reverse() >>

Reverse the prices list.

=cut
sub reverse {
    my ($self) = @_;
    my @prices = reverse @{$self->{'prices'}};
    $self->{'prices'} = \@prices;
}

=item C<< $p->convert_to_timeframe($timeframe) >>

Creates a new Prices object using the new timeframe by merging the
required prices. You can only convert to a largest timeframe.

=cut
sub convert_to_timeframe {
    my ($self, $timeframe) = @_;

    #WAR# WARN "new timeframe must be larger" unless ($timeframe > $self->timeframe);
    my $prices = GT::Prices->new($self->count);
    $prices->set_timeframe($timeframe);

    # Initialize the iteration
    my ($open, $high, $low, $close, $volume, $date) = @{$self->{'prices'}[0]};
    $volume = 0;
    my ($prevdate, $newdate);
    $prevdate = GT::DateTime::convert_date($date, $self->timeframe, $timeframe);

    # Iterate over all the prices (hope they are sorted)
    foreach my $q (@{$self->{'prices'}})
    {
	# Build the date in the new timeframe corresponding to the prices
	# being treated
	$newdate = GT::DateTime::convert_date($q->[$DATE], $self->timeframe,
					      $timeframe);
	# If the date differs from the previous one then we have completed
	# a new item
	if ($newdate ne $prevdate) {
	    # Store the new item
	    $prices->add_prices([ $open, $high, $low, $close, $volume, 
				  $prevdate ]);
	    # Initialize the open/high/low/close with the following item
	    $open = $q->[$OPEN];
	    $high = $q->[$HIGH];
	    $low  = $q->[$LOW];
	    $close = $q->[$CLOSE];
	    $volume = 0;
	}
	# Update the data of the item that is being built
	$high = ($q->[$HIGH] > $high) ? $q->[$HIGH] : $high;
	$low = ($q->[$LOW] < $low) ? $q->[$LOW] : $low;
	$close = $q->[$CLOSE];
	$volume += $q->[$VOLUME];

	# Update the previous date
	$prevdate = $newdate;
    }
    # Store the last item
    $prices->add_prices([ $open, $high, $low, $close, $volume, $prevdate ]);

    return $prices;
}

=item C<< $p->find_nearest_following_date($date) >>

=item C<< $p->find_nearest_preceding_date($date) >>

=item C<< $p->find_nearest_date($date) >>

Find the nearest date available

=cut
sub find_nearest_following_date {
    my ($self, $date) = @_;
    my $time = GT::DateTime::map_date_to_time($self->timeframe, $date);
    my $mindiff = $time;
    my $mindate = '';
    foreach (@{$self->{'prices'}})
    {
	my $dtime = GT::DateTime::map_date_to_time($self->timeframe, $_->[$DATE]);
	my $diff = $dtime - $time;
	next if ($diff < 0);
	if ($diff < $mindiff)
	{
	    $mindate = $_->[$DATE];
	    $mindiff = $diff;
	}
    }
    return $mindate;
}

sub find_nearest_preceding_date {
    my ($self, $date) = @_;
    my $time = GT::DateTime::map_date_to_time($self->timeframe, $date);
    my $mindiff = $time;
    my $mindate = '';
    foreach (@{$self->{'prices'}})
    {
	my $dtime = GT::DateTime::map_date_to_time($self->timeframe, $_->[$DATE]);
	my $diff = $time - $dtime;
	next if ($diff < 0);
	if ($diff < $mindiff)
	{
	    $mindate = $_->[$DATE];
	    $mindiff = $diff;
	}
    }
    return $mindate;
}

sub find_nearest_date {
    my ($self, $date) = @_;
    my $time = GT::DateTime::map_date_to_time($self->timeframe, $date);
    my $mindiff = $time;
    my $mindate = '';
    foreach (@{$self->{'prices'}})
    {
	my $dtime = GT::DateTime::map_date_to_time($self->timeframe, $_->[$DATE]);
	my $diff = abs($time - $dtime);
	if ($diff < $mindiff)
	{
	    $mindate = $_->[$DATE];
	    $mindiff = $diff;
	}
    }
    return $mindate;
}

=item C<< $p->loadtxt("cotationsfile.txt") >>

Load the prices from the text file.

=cut
sub loadtxt {
    my ($self, $file, $mark, $date_format, %fields) = @_;

    open(FILE, '<', "$file") || die "Can't open $file: $!\n";
    $self->{'prices'} = [];
    my ($open, $high, $low, $close, $volume, $date);
    my ($year, $month, $day);

    # Initialize all options with the default settings
    # Set up $mark as a tabulation
    if (!$mark) { $mark = "\t"; }

    # Set up %fields with the standard fields map : open high low close volume date
    if (!%fields) {
	%fields = ('open' => 0, 'high' => 1, 'low' => 2, 'close' => 3, 'volume' => 4, 'date' => 5);
    }
    
    # Set up $date_format to the US date format
    if (!$date_format) { $date_format = 0; }
    
    # Process each line in $file...
    while (defined($_=<FILE>))
    {
	# ... only if it's a line without strings (ie: everything but head line)
	if (!/\G[A-Za-z]/gc) {

	    # Get and split the line with $mark
	    chomp;
	    my @line = split("$mark");

	    # Get and swap all necessary fields according to the fields map
	    $open = $line[$fields{'open'}];
	    $high = $line[$fields{'high'}];
	    $low = $line[$fields{'low'}];
	    $close = $line[$fields{'close'}];
	    $volume = $line[$fields{'volume'}];
	    $date = $line[$fields{'date'}];

	    # Decode the date from the text file to something useable
		# The hh:nn:ss part is optional
	    # $date_format eq 0 : GeniusTrader Date Format (yyyy-mm-dd hh:nn:ss)
	    # $date_format eq 1 : US sort of Date Format   (mm/dd/yyyy)
	    # $date_format eq 2 : EU sort of Date Format   (dd/mm/yyyy)
	    
	    if ($date_format != 0) {
		
		if ($date_format eq 1) {
		    ($year, $month, $day) = Decode_Date_US($date);
		}
		if ($date_format eq 2) {
		    ($year, $month, $day) = Decode_Date_EU($date);
		}
		my ($today_year, $today_month, $today_day) = Today();
		if ($year > $today_year) {
		    $year -= 100;
		}
		$month = "0" . $month if $month < 10;
		$day = "0" . $day if $day < 10;
		$date = $year . "-" . $month . "-" .$day;
	    }

	    # Add all data within the GT::Prices object
	    $self->add_prices([ $open, $high, $low, $close, $volume, $date ]);
	}
    }
    close FILE;
}

=item C<< $p->savetxt("cotationsfile.txt") >>

Save the prices to the text file.

=cut
sub savetxt {
    my ($self, $file) = @_;
    open(FILE, '>', "$file") || die "Can't write in $file: $!\n";
    foreach (@{$self->{'prices'}})
    {
	print FILE join("\t", @{$_}) . "\n";
    }
    close FILE;
}

=item C<< $p->dump; >>

Print the prices on the standard output.

=cut
sub dump {
    my ($self) = @_;
    foreach (@{$self->{'prices'}})
    {
	print join("\t", @{$_}) . "\n";
    }
}

## PRIVATE FUNCTIONS

=item C<< $p->_binary_search($array_ref, $value) >>

Searches for the given $value in the $DATE position of the prices array.
This is an internal function, meant to be used only inside this object.

=cut
sub _binary_search {
	my ($array_ref, $value) = @_;
	my ($first, $last) = (0, scalar(@$array_ref)-1);

	while ($first <= $last) {
		my $middle = int(($first + $last) / 2);
		if ($$array_ref[$middle][$DATE] eq $value) {
			return $middle;
		} elsif ($$array_ref[$middle][$DATE] lt $value) {
			$first = $middle + 1;
		} else {
			$last = $middle - 1;
		}
	}
	return undef;
}


=pod

=back

=cut
1;
