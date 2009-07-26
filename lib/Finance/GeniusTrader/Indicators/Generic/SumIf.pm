package Finance::GeniusTrader::Indicators::Generic::SumIf;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("SumIf[#*]");

=head1 NAME

Finance::GeniusTrader::Indicators::Generic::SumIf - Return a sum depending on a signal

=head1 DESCRIPTION

This indicator takes three parameters. First a signal followed by a
period and an indicator. It returns the sum of the days where the Signal
is true. 

=over

=item {S:Generic:CrossOverUp {I:RSI} 80} 14 {I:SAR}

=back


=cut

sub initialize {
    my ($self) = @_;

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $sum = 0;

    return if ($calc->indicators->is_available($name, $i));

    for(my $n = $i - $nb + 1; $n <= $i; $n++)
    {
      if ($self->{'args'}->get_arg_values($calc, $n, 1)) {
	$sum += $self->{'args'}->get_arg_values($calc, $n, 3);
      }
    }

    $calc->indicators->set($name, $i, $sum);
}
