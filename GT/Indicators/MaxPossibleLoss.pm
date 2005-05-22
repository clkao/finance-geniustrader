package GT::Indicators::MaxPossibleLoss;

# Copyright 2000-2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);

@ISA = qw(GT::Indicators);
@NAMES = ("MaxPossibleLoss[#*]", "MaxPossibleLossDays[#*]");
@DEFAULT_ARGS = (20, "{I:Prices LOW}");


=head1 NAME

GT::Indicators::MaxPossibleLoss - Shows the maximal Loss for a long-strategy

=head1 DESCRIPTION

This indicator calculates the maximum loss that is possible in a
certain period of time. Be aware that this indicator "knows" the
future so don't use it for your trading strategies :)

=head1 PARAMETERS

=over

=item Number of days

The number of days the indicator looks in the future

=item Data

This is the data to use as input. If you don't specify anything, the
high price will be used by default.

=back


=cut

sub initialize {
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name(0);
    my $nameday = $self->get_name(1);
    my $lastday = $calc->prices->count();
    my $days = $self->{'args'}->get_arg_values($calc, $i, 1);

    return if ( $calc->indicators->is_available($name, $i) &&
		$calc->indicators->is_available($nameday, $i) );

    return if ($i+$days >= $lastday);

    my $res = $self->{'args'}->get_arg_values($calc, $i+1, 2) -
      $self->{'args'}->get_arg_values($calc, $i, 2);
    my $resday = 1;
    my $buy = $self->{'args'}->get_arg_values($calc, $i, 2);
    for (my $j=$i+1; $j<=$i+$days; $j++) {
      my $today = $self->{'args'}->get_arg_values($calc, $j, 2);
      if ( $today - $buy < $res ) {
	$res = $today - $buy;
	$resday = $j-$i;
      }
    }

    $calc->indicators->set($name, $i, $res);
    $calc->indicators->set($nameday, $i, $resday);

}
