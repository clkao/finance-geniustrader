package Finance::GeniusTrader::Tools;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# baseline 8 Jun 2005 9830 bytes
# $Id$

use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $PI);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(min max PI sign
                extract_object_number
                resolve_alias resolve_object_alias long_name short_name
                isin_checksum isin_validate isin_create_from_local
                get_timeframe_data parse_date_str find_calculator check_dates
                );
%EXPORT_TAGS = ("math" => [qw(min max PI sign)], 
		"generic" => [qw(extract_object_number)],
		"conf" => [qw(resolve_alias resolve_object_alias long_name short_name)],
		"isin" => [qw(isin_checksum isin_validate isin_create_from_local)],
                "timeframe" => [qw(get_timeframe_data parse_date_str find_calculator check_dates)]
		);

use Finance::GeniusTrader::DateTime;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::ArgsTree;
use Date::Calc qw( Date_to_Days );

=head1 NAME

Finance::GeniusTrader::Tools - Various helper functions

=head1 DESCRIPTION

This modules provides several helper functions that can be used in all
modules and scripts.

There are 5 groupings

=over 6

=item *   math      -- min, max, pi, sign

=item *   generic   -- extract_object_number

=item *   conf      -- resolve_alias resolve_object_alias long_name short_name

=item *   isin      -- isin_checksum isin_validate isin_create_from_local

=item *   timeframe -- get_timeframe_data parse_date_str find_calculator check_dates

=back

=head2 math

It provides mathematical functions, that can be imported with
use Finance::GeniusTrader::Tools qw(:math) :

=over 4

=item C<< PI() >>

Returns PI.

=item C<< min(...) >>

Returns the minimum of all given arguments.

=item C<< max(...) >>

Returns the maximum of all given arguments.

=item C<< sign($value) >>

Returns 1 for a positive (or null) value, -1 for a negative value.

=back

=cut
sub PI() { 3.14159265 }

sub max {
    my $max = $_[0];
    foreach (@_) {
	if (! defined($_)) {
	    warn "Finance::GeniusTrader::Tools::max called with undef argument !\n";
	    next;
	}
        if ( ! m/\d/ ) {
#           warn "Finance::GeniusTrader::Tools::max called with non-numeric argument \"$_\" !\n";
            next;
        }
	$max = ($_ > $max) ? $_ : $max;
    }
    return $max;
}

sub min {
    my $min = $_[0];
    foreach (@_) { 
	if (! defined($_)) {
	    warn "Finance::GeniusTrader::Tools::min called with undef argument !\n";
	    next;
	}
        if ( ! m/\d/ ) {
#           warn "Finance::GeniusTrader::Tools::min called with non-numeric argument \"$_\" !\n";
            next;
        }
	$min = ($_ < $min) ? $_ : $min;
    }
    return $min;
}

sub sign {
    ($_[0] >= 0) ? 1 : -1;
}

=pod

=head2 generic

It provides helper functions to manage arguments in "Generic" objects.
You can import those functions with use Finance::GeniusTrader::Tools qw(:generic) :

=over 4

=item C<< extract_object_number(@args) >>

Returns the number associated to the first the object described
by the arguments. 

=back

=cut
sub extract_object_number {
    my ($name) = shift;
    if ($name =~ m#/(\d+)$#)
    {
	return $1 - 1;
    }
    return 0;
}

=pod

=head2 conf

And a few other very-specific functions :

use Finance::GeniusTrader::Tools qw(:conf) :

=over

=item C<< resolve_alias($alias) >>

Return the long name of the system as described in the configuration
file.

=cut
sub resolve_alias {
    my ($alias) = @_;
    my $name = $alias;
    my @param;
    if ($alias =~ m/^\s*(.*)\s*\[(.*)\]\s*$/) {
	$name = $1;
	@param = split(",", $2);
    }
    my $sysname = '';
    if (scalar @param) {
	$sysname = Finance::GeniusTrader::Conf::get("Aliases::Global::$name" . "[]");
    } else {
	$sysname = Finance::GeniusTrader::Conf::get("Aliases::Global::$name");
    }
    if (! $sysname)
    {
        die "$0: error: Alias `$alias' wasn't found in options file!"
         .  "\nkey looked for was \"Aliases::Global::$name\"\n";
    }
    # The alias content may list another alias ...
    while ($sysname !~ /:/) {
	$sysname = resolve_alias($sysname);
    }
    my $n = 1;
    foreach (@param)
    {
	$sysname =~ s/#$n/$_/g;
	$n++;
    }

    # Take care about operators + - / * in a string like #1+#2
    eval {
	$sysname =~ s|(\d+)\*(\d+)| $1 * $2 |eg;
	$sysname =~ s|(\d+)\/(\d+)| $1 / $2 |eg;
	$sysname =~ s|(\d+)\+(\d+)| $1 + $2 |eg;
	$sysname =~ s|(\d+)\-(\d+)| $1 - $2 |eg;
    };
    
    if ($sysname =~ /#(\d+)/)
    {
	die "The alias '$alias' is lacking the parameter number $1.\n";
    }
    return $sysname;
}

=item C<< resolve_object_alias($alias, @param) >>

Return the complete description of the object designed by "alias". @param
is the array of parameters as returned by Finance::GeniusTrader::ArgsTree::parse_args().

Object aliases can be defined in global files (as defined in the option
Path::Aliases::<object_kind>), for each kind of object (e.g., Signals, 
Indicators, etc.), or in user-specific files (~/.gt/aliases/<object_kind>).

Such aliases are defined via the syntax
  <alias_name>   <definition>

For example
  MyMean  { I:Generic:Eval ( #1 + #2 ) / 2 }

An object alias can also be defined in the option file with the syntax
  Aliases::<object_kind>::<alias_name>    <definition>

For example:

 Aliases::Indicators::MyMean  { I:Generic:Eval ( #1 + #2 ) / 2 }

Then you can use this alias in any other place where you could have used
a standard indicator as argument. Here's how you would reference it with
custom parameters :

 { @I:MyMean 50 {I:RSI} }

If you don't need any parameters then you can just say "@I:MyMean".

=cut
sub resolve_object_alias {
    my ($alias, @param) = (@_);

    # Lookup the alias
    my $def = Finance::GeniusTrader::Conf::get("Aliases\::$alias");
    
    my $n = 1;
    foreach my $arg (Finance::GeniusTrader::ArgsTree::args_to_ascii(@param))
    {
	$def =~ s/#$n/$arg/g;
	$n++;
    }

    # Take care about operators + - / * in a string like #1+#2
    eval {
	$def =~ s|(\d+)\*(\d+)| $1 * $2 |eg;
	$def =~ s|(\d+)\/(\d+)| $1 / $2 |eg;
	$def =~ s|(\d+)\+(\d+)| $1 + $2 |eg;
	$def =~ s|(\d+)\-(\d+)| $1 - $2 |eg;
    } if $def;
    
    return $def;
}

=item C<< my $l = long_name($short) >>

=item C<< my $s = short_name($long) >>

Most module names can be shortened with some standard abreviations. Those
functions let you switch between the long and the short version of the
names. The recognized abreviations are :

=over 6

=item * Analyzers:: = A:

=item * CloseStrategy:: = CS:

=item * Generic:: = G:

=item * Indicators:: = I:

=item * MoneyManagement:: = MM:

=item * OrderFactory:: = OF:

=item * Signals:: = S:

=item * Systems:: = SY:

=item * TradeFilters:: = TF:

=back

=cut
sub long_name {
    my ($name) = @_;

    $name =~ s/A::?/Analyzers::/g;
    $name =~ s/CS::?/CloseStrategy::/g;
    $name =~ s/OF::?/OrderFactory::/g;
    $name =~ s/TF::?/TradeFilters::/g;
    $name =~ s/MM::?/MoneyManagement::/g;
    $name =~ s/SY::?/Systems::/g;
    $name =~ s/S::?/Signals::/g;
    $name =~ s/I::?/Indicators::/g;
    $name =~ s/G::?/Generic::/g;
    $name =~ s/:+/::/g;

    return $name;
}
sub short_name {
    my ($name) = @_;

    $name  =~ s/Generic::?/G:/g;
    $name  =~ s/Indicators::?/I:/g;
    $name  =~ s/Systems::?/SY:/g;
    $name  =~ s/Signals::?/S:/g;
    $name  =~ s/TradeFilters::?/TF:/g;
    $name  =~ s/CloseStrategy::?/CS:/g;
    $name  =~ s/MoneyManagement::?/MM:/g;
    $name  =~ s/OrderFactory::?/OF:/g;
    $name  =~ s/Analyzers::?/A:/g;
    $name  =~ s/::/:/g;

    return $name;
}

=back

=head2 isin

use Finance::GeniusTrader::Tools qw(:isin) :

=over 4

=item C<< isin_checksum($code) >>

This computes the checksum of a given code. The whole ISIN is returned.

=cut
sub isin_checksum {
    my $isin = shift;
    my $tmp = "";
    return if (length($isin) < 11);
    $isin = substr($isin, 0, 11);

    # Gernerate lookup
    my %lookup = ();
    my $c = 10;
    foreach ( "A".."Z" ) {
    $lookup{$_} = $c;
    $c++;
    }

    # Transform into numbers
    for (my $i=0; $i<length($isin); $i++) {
    if (defined($lookup{uc(substr($isin, $i, 1))}) ) {
      $tmp .= $lookup{uc(substr($isin, $i, 1))};
    } else {
      $tmp .= substr($isin, $i, 1);
    }
    }

    # Computation of the checksum
    my $checksum = 0;
    my $multiply = 2;
    for (my $i=length($tmp)-1; $i>=0; $i--) {
    my $t = ( $multiply * substr($tmp, $i, 1) );
    $t = 1 + ($t % 10) if ($t >= 10);
    $checksum += $t;
    $multiply = ($multiply==2) ? 1 : 2;
    }
    $checksum = 10 - ($checksum % 10);
    $checksum = 0 if ($checksum == 10);

    return $isin . $checksum;
}

=item C<< isin_validate($isin) >>

Validate the ISIN and its checksum.

=back

=cut
sub isin_validate {
    my $isin = shift;
    my $isin2 = isin_checksum($isin);   
    return if (!defined($isin2));
    return 1 if ($isin eq $isin2);
    return 0;
}

sub isin_create_from_local {
    my ($country, $code) = @_;
    $country = uc($country);
    while ( length($code) < 9 ) {
    $code = "0" . $code;
    }
    my $isin = isin_checksum("$country$code");
    return $isin;
}

=head2 timeframe

use Finance::GeniusTrader::Tools qw(:timeframe) :

=over 4

=item C<< GetTimeFrameData ($code, $timeframe, $db, $max_loaded_items) >>

Returns a prices and a calculator object with data for the required
$code in the specified $timeframe. It uses $db object to fetch the data.
If for instance, weekly data is requested, but only daily data is available,
the weekly data is calculated from the daily data.

Optionally, you can set the configuration file directive DB::timeframes_available
to specify which timeframes are available.
For instance:
DB::timeframes_available 5min,hour,day

=cut
sub get_timeframe_data {
my ($code, $timeframe, $db, $max_loaded_items) = @_;
#WAR# WARN "Fetching all available data, because the max_loaded_items parameter was not set." unless(defined($max_loaded_items));
$max_loaded_items = -1 unless(defined($max_loaded_items));
my @tf;
my $available_timeframes = Finance::GeniusTrader::Conf::get('DB::timeframes_available');
my $q;

die("Max loaded items cannot be zero") if ($max_loaded_items==0);
die("Parameter \$code not set in get_timeframe_data") if (!defined($code));
die("Parameter \$timeframe not set in get_timeframe_data") if (!defined($timeframe));
die("Parameter \$db not set in get_timeframe_data") if (!defined($db));

if (defined($available_timeframes)) {
	foreach my $tf_name (split(',', $available_timeframes)) {
	        my $tf_code = Finance::GeniusTrader::DateTime::name_to_timeframe($tf_name);
		push @tf, $tf_code;
		if (!defined($tf_code)) {
		    my $tfs = join("\n\t", map(Finance::GeniusTrader::DateTime::name_of_timeframe($_), Finance::GeniusTrader::DateTime::list_of_timeframe));
		    die("Invalid timeframe name in available_timeframes configuration item: $tf_name\n\nValid timeframes are: \n\t" . $tfs . "\n\n");
		}
	}
	@tf = sort(@tf);
} else {
	@tf = Finance::GeniusTrader::DateTime::list_of_timeframe;
}

#ERR#  ERROR  "Invalid db argument in get_timeframe_data" unless ( ref($db) =~ /Finance::GeniusTrader::DB/);
#ERR#  ERROR  "Timeframe parameter not set in get_timeframe_data." unless(defined($timeframe));

foreach(reverse(@tf)) {
  next if ($_ > $timeframe);
  $q = $db->get_last_prices($code, $max_loaded_items, $_);
  last if ($q->count > 0);
}

if (!defined($q) || $q->count == 0) {
my $msg="No data available to generate ".Finance::GeniusTrader::DateTime::name_of_timeframe($timeframe)." data.";
$msg.="\nAvailable timeframes are: ($available_timeframes)" if (defined($available_timeframes));
die($msg);
}

warn ("No data is available to complete the request for $code") if ($q && $q->count == 0);
my $calc = Finance::GeniusTrader::Calculator->new($q);
$calc->set_code($code);

if ($q->timeframe != $timeframe) {
    $calc->set_current_timeframe($timeframe);
    $q = $calc->prices;
}

return ($q, $calc);
}

sub parse_date_str {
    #
    # inputs: date string reference var required
    #         error string reference var (optional)
    # returns 1 for good date
    #         zero (null) for bad date
    #
    # notes: @ if called in void context with bad date value the internal
    #          error handling will put error message text on stderr and die called
    #        @ date ref var may be altered to conform to std date-time format
    #        @ error string will contain details about bad date-time string
    #
    # usage examples
    # typical usage in perl script
    # my $err_msg;
    # if ( ! parse_date_str( \$date, \$err_msg ) ) {
    #   die "Error: $err_msg\n";
    # }
    #
    # usage using internal error handling
    # my $date = "24oct07";
    # parse_date_str( \$date  );
    #
    my ( $dtstref, $errref ) = @_;

    if ( eval { require Date::Manip } ) {
        use Date::Manip qw(ParseDate UnixDate);
        if ( $$dtstref =~ m/[- :\w\d]/ ) {
            if ( my $date = ParseDate($$dtstref) ) {
                $$dtstref = UnixDate("$date", "%Y-%m-%d %T");
            }
        }
    }
    # dates only allow digits, date separator is '-', time separator is ':'
    # date and time field separator is a single space not even a tab
    #
    # timeframe seps: '-' day and week
    #                 '/' month
    #                 '_' date and time part separator
    if ( $$dtstref =~ m/[^- :\d]/ ) {
      # bad chars in date string
      $$errref = "invalid character in date \"$$dtstref\"" if ( $errref );
      return if defined wantarray;
      die "pds: invalid character in date \"$$dtstref\"\n";
    }
    my ( $year, $mon, $day, $time )
        = $$dtstref =~ /^(\d{4})-?(\d{2})-?(\d{2})\s?([\d:]+)*$/;
        # not capturing time field separator intentionally
    if ( ! $year || ! $mon || ! $day ) {
        $$errref = "bad date format \"$$dtstref\"" if ( $errref );
        return if defined wantarray;
        die "pds: bad date format \"$$dtstref\"\n";
    }

    # valididate date
    if ( ! Date::Calc::check_date($year, $mon, $day) ) {
        $$errref = "invalid date \"$$dtstref\"" if ( $errref );
        return if defined wantarray;
        die "pds: invalid date \"$$dtstref\"\n";
    }

    # valididate time
    if ( $time ) {
        my ( $hour, $min, $sec ) = split /:/, $time;
        if ( ! Date::Calc::check_time($hour, $min, $sec) ) {
          #print STDERR "pds: invalid time \"$hour:$min:$sec\"\n";
          #return 0 if ( defined wantarray );
          $$errref = "invalid time \"$time\"" if ( $errref );
          return if defined wantarray;
          die "pds: invalid time \"$time\"\n";
        }
    }

    # good date
    # clear err just in case
    $$errref = "" if ( $errref );

    return 1;

=pod

=item C<< parse_date_str ( \$date_string, \$err_msg ) >>

Returns 1 if \$date_string is valid parsable date, zero (or null) otherwise
\$date_string will be altered to be a gt compliant date string on return
\$err_msg is optional

=over 6

=item * input params must be references to the object

=item * if called in void context with bad date value the internal
error handling will put error message text on stderr and die called

=item * date ref var may be altered to conform to std date-time format

=item * error string will contain details about bad date-time string

=back

If the user has Date::Manip installed it allows the use of date strings
that can be parsed by Date::Manip in addition the to defacto standard
date-time format accepted by GT (YYYY-MM-DD HH:MM:SS) time part is optional

Date::Manip is not required, without it users cannot use short-cuts to
specify date strings. such short cuts include
 --start '6 months ago'
 --end 'today'

The date string checking includes verifying the date string format
is valid and the date is a valid date (and time if provided)

Errors will be displayed and the script will terminate.

=head3 Application usage examples:

with Date::Manip installed

 %    scan.pl --timeframe day --start '6 months ago' \
         --end 'today' market_file 'today' system_file

without Date::Manip you will need to use:

 %    scan.pl --timeframe day --start 2007-04-24 \
         --end 2007-10-24 market_file 2007-10-24 system_file

 or

 %    scan.pl --timeframe week --start 2007-04-24 
         --end 2007-10-24 market_file 2007-10-24 system_file

=head3 Usage of parse_date_str in application script

  use Finance::GeniusTrader::Tools qw( :timeframe );  
  # tag name to get &parse_date_str visibility

  my $err_msg;
  # get date string from command line
  my $date = shift;

  my ( $d_yr, $d_mn, $d_dy, $d_tm );
  if ( ! parse_date_str( \$date, \$err_msg ) ) {
    die "Error: $err_msg\n";
  } else {
    ( $d_yr, $d_mn, $d_dy, $d_tm ) = split /[- ]/, $date;
  }

=cut
} # sub parse_date_str

=item C<< find_calculator($code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_item) >>

Find a calculator: Returns $calc (the calculator), as well as
$first and $last (indices used by the calculator).

The interval examined (bound by $first and $last) is computed as follows (stop whenever $first and $last have been determined):
1. if present, use --start (otherwise default $first to 2 years back) and --end (otherwise default $last to last price)
2. use --nb-item (from first or last, whichever has been determined), if present
3. use first or last price, whichever has not yet been determined, if --full is present
4. otherwise, use two years worth of data.

Note that the values given to --start and --end are relative to the selected time frame (i.e., if timeframe is "day", these indicate a date; if timeframe is "week", these indicate a week; etc.). Format is "YYYY-MM-DD" for dates, "YYYY-WW" for weeks, "YYYY-MM" for months, and "YYYY" for years.

=cut

sub find_calculator {
  my ($db, $code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items) = @_;
  $nb_item ||= 0;
  $max_loaded_items ||= -1;

  if (!defined $timeframe) {
    my $msg = "Unkown timeframe. Available timeframes are:\n";
    foreach (Finance::GeniusTrader::DateTime::list_of_timeframe()) {
      $msg .= "\t".Finance::GeniusTrader::DateTime::name_of_timeframe($_) . "\n";
    }
    die($msg);
  }

  my ($prices, $calc) = get_timeframe_data($code, $timeframe, $db, $max_loaded_items);

  my $c = $prices->count;
  my $first;
  my $last;
  $last = $c - 1 unless ($end || $start);
  if ($end) {
    my $date = $prices->find_nearest_preceding_date($end);
    $last = $prices->date($date);
  }
  if ($start) {
    my $date = $prices->find_nearest_following_date($start);
    $first = $prices->date($date);
  }
  unless ($start) {
    $first = $last - 2 * Finance::GeniusTrader::DateTime::timeframe_ratio($YEAR, 
						     $calc->current_timeframe);
    $first = 0 if ($full);
    $first = $last - $nb_item + 1 if ($nb_item);
    $first = 0 if ($first < 0);
  }
  unless ($last) {
    $last = $first + 2 * Finance::GeniusTrader::DateTime::timeframe_ratio($YEAR, 
						     $calc->current_timeframe);
    $last = $c - 1 if ($full);
    $last = $first + $nb_item - 1 if ($nb_item);
    $last = $c - 1 if ($last >= $c);
  }

  return ($calc, $first, $last);

}

=item C<< check_dates($timeframe, $start, $end, $date) >>

Converts the given dates into the proper dates relative to the 
chosen time frame, if necessary. For example, if a date 2000-02-01
is given with --timeframe=week, this date is converted to 2000-05.

Verifies that the start date is before the end.

If a third date is given, verifies that this date is between the
start and end dates.

=cut

sub check_dates {

  my $timeframe = $_[0];
  my $start = $_[1];
  my $end = $_[2];
  my $date = $_[3] || 0;

  my $err_msg;

  $timeframe = $DAY unless ( $timeframe );

  my ( $s_yr, $s_mn, $s_dy, $s_tm );
  if ( $start ) {
    if ( ! parse_date_str( \$start, \$err_msg ) ) {
      die "Error: \$err_msg\n";
    } else {
      ( $s_yr, $s_mn, $s_dy, $s_tm ) = split /[- ]/, $start;
    }
  }

  my ( $e_yr, $e_mn, $e_dy, $e_tm );
  if ( $end ) {
    if ( ! parse_date_str( \$end, \$err_msg ) ) {
      die "Error: \$err_msg\n";
    } else {
      ( $e_yr, $e_mn, $e_dy, $e_tm ) = split /[- ]/, $end;
    }
  }

  if ( $start && $end ) {
    # $start must be prior to $end
    if (Date_to_Days($s_yr, $s_mn, $s_dy) >=
	Date_to_Days($e_yr, $e_mn, $e_dy)) {
      die "Error: --start date $start must be prior to --end date $end\n";
    }
  }
  
  # timeframe relative date conversions
  if ( $start && $timeframe != $DAY ) {
    $start = Finance::GeniusTrader::DateTime::convert_date($start, $DAY, $timeframe);
  }

  if ( $end && $timeframe != $DAY ) {
    $end = Finance::GeniusTrader::DateTime::convert_date($end, $DAY, $timeframe);
  }

  my ( $d_yr, $d_mn, $d_dy, $d_tm );
  if ( $date ) {
    if ( ! parse_date_str( \$date, \$err_msg ) ) {
      die "Error: $err_msg\n";
    } else {
      ( $d_yr, $d_mn, $d_dy, $d_tm ) = split /[- ]/, $date;
    }

    if ( $end ) {
      # $date must be $end or before
      if (Date_to_Days($d_yr, $d_mn, $d_dy) >
	  Date_to_Days($e_yr, $e_mn, $e_dy)) {
	die "Error: date $date must be prior to or equal to --end date $end\n";
      }
    }
  
    if ( $start ) {
      # $start must be prior to $date
      if (Date_to_Days($s_yr, $s_mn, $s_dy) >=
	  Date_to_Days($d_yr, $d_mn, $d_dy)) {
	die "Error: --start $start must be prior to date $date\n";
      }
    }

    if ( $timeframe != $DAY && $timeframe > $DAY ) {
      $date = Finance::GeniusTrader::DateTime::convert_date($date, $DAY, $timeframe);
    }
    
    $_[3] = $date;

  }

  $_[1] = $start;
  $_[2] = $end;

}

=back

=cut
1;
