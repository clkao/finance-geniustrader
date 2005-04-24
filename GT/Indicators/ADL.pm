package GT::Indicators::ADL;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("ADL[#*]");
@DEFAULT_ARGS = ("{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices VOLUME}", "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::ADL - Accumulation/Distribution line

=head1 DESCRIPTION

=head2 Overview

The Accumulation/Distribution Line was developed by Marc Chaikin to assess the cumulative flow of money into and out of a security.

=head2 Calculation

The ADL is the cumulative sum of (((Close - Low) - (High - Close)) / (High - Low)) * Volume

=head2 Links

http://www.stockcharts.com/education/What/IndicatorAnalysis/indic_AccumDistLine.html
http://www.equis.com/free/taaz/accumdistr.html

=cut
sub initialize {
    my $self = shift;
    $self->add_arg_dependency(1,1);
    $self->add_arg_dependency(2,1);
    $self->add_arg_dependency(3,1);
    $self->add_arg_dependency(4,1);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $adl = 0;
    my $ad = 0;

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $prices = $calc->prices;
    my $high = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $low = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $close = $self->{'args'}->get_arg_values($calc, $i, 4);
    my $vol = $self->{'args'}->get_arg_values($calc, $i, 3);

    if ($calc->indicators->is_available($name, $i - 1)) {
	$adl = $calc->indicators->get($name, $i - 1);
	if ($high != $low) {
	    $ad = ((($close - $low) - ($high - $close)) / ($high - $low)) * $vol;
	}
	$adl += $ad;
	$calc->indicators->set($name, $i, $adl);
    } else {
	for(my $n = 0; $n <= $i; $n++)
	{
	    $high = $self->{'args'}->get_arg_values($calc, $n, 1);
	    $low = $self->{'args'}->get_arg_values($calc, $n, 2);
	    $close = $self->{'args'}->get_arg_values($calc, $n, 4);
	    $vol = $self->{'args'}->get_arg_values($calc, $n, 3);

	    if ($high != $low) {
		$ad = ((($close - $low) - ($high - $close)) / ($high - $low)) * $vol;
	    }
	    $adl += $ad;
	    $calc->indicators->set($name, $n, $adl);
	}
    }
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    $self->calculate($calc, $last);
}

1;
