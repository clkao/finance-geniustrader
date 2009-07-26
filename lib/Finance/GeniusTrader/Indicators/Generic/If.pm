package Finance::GeniusTrader::Indicators::Generic::If;

# Copyright 2000-2003 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("If[#*]");

=head1 NAME

Finance::GeniusTrader::Indicators::Generic::If - Return a value or another depending on a signal

=head1 DESCRIPTION

This indicator takes three parameters. First a signal followed by two indicators.
if the signal is true it returns the value of the first indicator, otherwise it
returns the value of the second indicator.

=over

=item {S:Prices:Advance} {I:Generic:MaxInPeriod 5} {I:Generic:MinInPeriod 5}

=item {S:Generic:CrossOverUp {I:RSI} 80} {I:SAR} {I:Generic:MaxInPeriod 10}

=back

=cut
sub initialize {
    my ($self) = @_;

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $value;
    
    return if ($calc->indicators->is_available($name, $i));

    if ($self->{'args'}->get_arg_values($calc, $i, 1)) {
	$value = $self->{'args'}->get_arg_values($calc, $i, 2);
    } else {
	$value = $self->{'args'}->get_arg_values($calc, $i, 3);
    }
    
    if (defined($value)) {
	$calc->indicators->set($name, $i, $value);
    }
}
