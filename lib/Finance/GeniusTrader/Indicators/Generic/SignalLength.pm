package Finance::GeniusTrader::Indicators::Generic::SignalLength;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("SignalLength[#1]");

=head1 NAME

Finance::GeniusTrader::Indicators::Generic::SignalLength - Length of any signal

=head1 DESCRIPTION

This indicator returns the number of consecutive periods where the signal
in parameter has been detected.

=cut
sub initialize {
    my ($self) = @_;

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $res = 0;
    
    return if ($calc->indicators->is_available($name, $i));
    my $sig_value = $self->{'args'}->get_arg_values($calc, $i, 1);
    return if (! defined $sig_value);

    if ($sig_value) {
	my $sum_yesterday = undef;
	if ($i >= 1 and $calc->indicators->is_available($name, $i - 1)) {
	    $sum_yesterday = $calc->indicators->get($name, $i - 1);
	    $res = $sum_yesterday + 1;
	} else {
	    my $n = $i - 1;
	    $res = 1;
	    while ($n >= 0) {
		my $value = $self->{'args'}->get_arg_values($calc, $n, 1);
		if (defined($value) && $value) {
		    $res++;
		    $n--;
		} else {
		    last;
		}
	    }
	}
    } else {
	$res = 0;
    }
    
    $calc->indicators->set($name, $i, $res);
}
