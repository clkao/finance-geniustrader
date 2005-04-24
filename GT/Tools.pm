package GT::Tools;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT_OK %EXPORT_TAGS $PI);

require Exporter;
@ISA = qw(Exporter);
@EXPORT_OK = qw(min max extract_object_number resolve_alias
		resolve_object_alias PI sign long_name short_name
		isin_checksum isin_validate isin_create_from_local);
%EXPORT_TAGS = ("math" => [qw(min max PI sign)], 
		"generic" => [qw(extract_object_number)],
		"conf" => [qw(resolve_alias resolve_object_alias long_name short_name)],
		"isin" => [qw(isin_checksum isin_validate isin_create_from_local)]
		);

use GT::Prices;
use GT::Eval;
use GT::ArgsTree;

use Carp qw(cluck);

=head1 NAME

GT::Tools - Various helper functions

=head1 DESCRIPTION

This modules provides several helper functions that can be used in all
modules.

It provides mathematical functions, that can be imported with
use GT::Tools qw(:math) :

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

It provides helper functions to manage arguments in "Generic" objects.
You can import those functions with use GT::Tools qw(:generic) :

=over 4

=item C<< extract_object_number(@args) >>

Returns the number associated to the first the object described
by the arguments. 

=back

=cut
sub PI() { 3.14159265 }

sub max {
    my $max = $_[0];
    foreach (@_) {
	if (! defined($_)) {
	    cluck "GT::Tools::max called with undef argument !\n";
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
	    cluck "GT::Tools::min called with undef argument !\n";
	    next;
	}
	$min = ($_ < $min) ? $_ : $min;
    }
    return $min;
}

sub sign {
    ($_[0] >= 0) ? 1 : -1;
}

sub extract_object_number {
    my ($name) = shift;
    if ($name =~ m#/(\d+)$#)
    {
	return $1 - 1;
    }
    return 0;
}

=pod

And a few other very-specific functions :

=over

=item C<< resolve_alias($alias) >>

Return the long name of the system as described in the configuration
file.

=cut
sub resolve_alias {
    my ($alias) = @_;
    my $name = $alias;
    my @param;
    if ($alias =~ m/^(.*)\[(.*)\]$/) {
	$name = $1;
	@param = split(",", $2);
    }
    my $sysname = '';
    if (scalar @param) {
	$sysname = GT::Conf::get("Aliases::Global::$name" . "[]");
    } else {
	$sysname = GT::Conf::get("Aliases::Global::$name");
    }
    if (! $sysname)
    {
	die "Alias `$alias' doesn't exist !\n";
    }
    # The alias content may list another alias ...
    while ($sysname !~ /\|/) {
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
is the array of parameters as returned by GT::ArgsTree::parse_args().

Object aliases can be defined in global files
(/usr/share/geniustrader/aliases/indicators for example) or in custom
files (~/.gt/aliases/indicators) or in the standard configuration file
with entries like this one :

 Aliases::Indicators::MyMean  { I:Generic:Eval ( #1 + #2 ) / 2 }

Then you can use this alias in any other place where you could have used
a standard indicator as argument. Here's how you would reference it with
custom parameters :

 { @I:MyMean 50 {I:RSI} }

If you don't need any parameters then you can just say "@I:MyMean".

=cut
sub resolve_object_alias {
    my ($alias, @param) = (@_);

    # Load the various definition of aliases
    GT::Conf::default('Path::Aliases::Signals', '/usr/share/geniustrader/aliases/signals');
    GT::Conf::default('Path::Aliases::Indicators', '/usr/share/geniustrader/aliases/indicators');
    GT::Conf::default('Path::Aliases::Systems', '/usr/share/geniustrader/aliases/systems');
    GT::Conf::default('Path::Aliases::CloseStrategy', '/usr/share/geniustrader/aliases/closestrategy');
    GT::Conf::default('Path::Aliases::MoneyManagement', '/usr/share/geniustrader/aliases/moneymanagement');
    GT::Conf::default('Path::Aliases::TradeFilters', '/usr/share/geniustrader/aliases/tradefilters');
    GT::Conf::default('Path::Aliases::OrderFactory', '/usr/share/geniustrader/aliases/orderfactory');
    
    foreach my $kind ("Signals", "Indicators", "Systems", "CloseStrategy", 
		      "MoneyManagement", "TradeFilters", "OrderFactory")
    {
	foreach my $file ($ENV{'HOME'}."/.gt/aliases/".lc($kind), GT::Conf::get("Path::Aliases::$kind"))
	{
	    next if not -e $file;
	    open(ALIAS, "<$file") || die "Can't open $file : $!\n";
	    while (defined($_=<ALIAS>)) {
		if (/^\s*(\S+)\s+(.*)$/) {
		    GT::Conf::default("Aliases::$kind\::$1", $2);
		}
	    }
	    close ALIAS;
	}
    }
    
    # Lookup the alias
    my $def = GT::Conf::get("Aliases::$alias");
    
    my $n = 1;
    foreach my $arg (GT::ArgsTree::args_to_ascii(@param))
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
    };
    
    return $def;
}

=item C<< my $l = long_name($short) >>

=item C<< my $s = short_name($long) >>

Most module names can be shortened with some standard abreviations. Those
functions let you switch between the long and the short version of the
names. The recognized abreviations are :

=over

=item Indicators:: = I:

=item Signals:: = S:

=item Systems:: = SY:

=item CloseStrategy:: = CS:

=item OrderFactory:: = OF:

=item TradeFilters:: = TF:

=item MoneyManagement:: = MM:

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
    $name =~ s/:+/::/g;

    return $name;
}
sub short_name {
    my ($name) = @_;

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

=back

=cut
1;
