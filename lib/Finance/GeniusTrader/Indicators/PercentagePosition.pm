package GT::Indicators::PercentagePosition;

# Copyright 2000-2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);
use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("PercentagePosition[#*]");
@DEFAULT_ARGS = (65, "{I:Prices CLOSE}");


=head1 NAME

GT::Indicators::PercentagePosition - Relative Position in a certain period

=head1 DESCRIPTION

This indicators calculates the realtive position in a period. Zero
means that a new low is reached and 100 corresponds to a new high.

=head1 PARAMETERS

=over

=item Period 1

The number of days in which the indicator looks for a high/low. 

=item Indicator 

The source

=back

=cut

sub initialize {
    my ($self) = @_;
}


sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $indic = $calc->indicators;
    my $nbdays = $self->{'args'}->get_arg_values($calc, $i, 1);

    return if ($calc->indicators->is_available($name, $i));

    $self->remove_volatile_dependencies();
    $self->add_volatile_prices_dependency($nbdays);
    return if (! $self->check_dependencies($calc, $i));

    my $start = $i - $nbdays;
    $start = 0 if ($nbdays == -1);
    $start = 0 if ($start < 0);

    my $min = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $max = $min;
    my $actual = $min;
    for (my $j=$start; $j<=$i; $j++) {
      my $today = $self->{'args'}->get_arg_values($calc, $j, 2);
      $min = $today if ($today<$min);
      $max = $today if ($today>$max);
    }

    my $res = ($max-$min==0) ? 0 : 100*($actual-$min)/($max-$min);
    $calc->indicators->set($name, $i, $res);
}
