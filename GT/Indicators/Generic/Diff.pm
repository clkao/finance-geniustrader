package GT::Indicators::Generic::Diff;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);
use GT::ArgsTree;

@ISA = qw(GT::Indicators);
@NAMES = ("Diff[#*]");
@DEFAULT_ARGS = ("{I:Prices CLOSE}", 1);

=head1 NAME

GT::Indicators::Generic::Diff - Difference between two days

=head1 DESCRIPTION 

Calculates the difference between the actual value and the value n
days ago.

=over

=item {I:RSI} 14

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

    my $nb = $self->{'args'}->get_arg_values($calc, $i, 2);
    if ( defined($nb) ) {
      my $present = $self->{'args'}->get_arg_values($calc, $i, 1);
      my $past =  $self->{'args'}->get_arg_values($calc, $i-$nb, 1);
      $value = $present - $past;
    }

    if ( defined($value) ) {
      $calc->indicators->set($name, $i, $value);
    }
}

1;
