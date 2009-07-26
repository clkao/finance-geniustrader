package Finance::GeniusTrader::Indicators::Cheating::ForwardKPercent;

# Copyright 2000-2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Tools qw(:math);
use Finance::GeniusTrader::Indicators::Generic::MaxInPeriod;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("ForwardKPercent[#*]");
@DEFAULT_ARGS = (3, "{I:Prices CLOSE}", "{I:Prices HIGH}", "{I:Prices LOW}", );

=head1 NAME

Finance::GeniusTrader::Indicators::ForwardKPercent - Probability to make a profitable trade

=head1 DESCRIPTION

This indicator calculates the K%-value:

              CLOSE - MIN(3, Low)
K% (3) = ------------------------------
           MAX(3, HIGH) - MIN(3,Low)

Be aware that this indicator "knows" the future so don''t use it for
your trading strategies :)

=head1 PARAMETERS

=over

=item Number of days 

The number of days the indicator looks in the future

=back


=cut

sub initialize {
    my ($self) = @_;
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $lastday = $calc->prices->count();
    my $days = $self->{'args'}->get_arg_values($calc, $i, 1);

    return if ( $calc->indicators->is_available($name, $i) );
    return if ($i+$days >= $lastday);

    my $close = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $high = $self->{'args'}->get_arg_values($calc, $i, 3);
    my $low = $self->{'args'}->get_arg_values($calc, $i, 4);

    for (my $j=$i+1; $j<=$i+$days; $j++) {
      my $t_high = $self->{'args'}->get_arg_values($calc, $j, 3);
      my $t_low = $self->{'args'}->get_arg_values($calc, $j, 4);
      $high = $t_high if ( $t_high > $high );
      $low = $t_low if ( $t_low < $low );
    }

    my $res = ( $close - $low ) / ( $high - $low );

    $calc->indicators->set($name, $i, $res);

}
