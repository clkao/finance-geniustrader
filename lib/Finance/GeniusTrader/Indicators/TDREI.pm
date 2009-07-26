package GT::Indicators::TDREI;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);
use GT::ArgsTree;
use GT::Indicators::Generic::Eval;


@ISA = qw(GT::Indicators);
@NAMES = ("TDREI[#*]");
@DEFAULT_ARGS = (2, 5, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}"); # Momentum, Period

=head1 NAME

GT::Indicators::TDREI - Tom Demarks REI

=head1 DESCRIPTION 

A new oscillator introduced by Tom DeMark.

=head2 Parameters

=over

=item Momentum (default 2)

=item Period (default 10)

=back

=head2 Creation

 GT::Indicators::TDREI->new()

=head2 Links

=cut


sub initialize {
    my $self = shift;
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name;

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(3, 2 * ( $self->{'args'}->get_arg_values($calc, $i, 1) + 
				       $self->{'args'}->get_arg_values($calc, $i, 2) + 1) );
    $self->add_volatile_arg_dependency(4, 2 * ($self->{'args'}->get_arg_values($calc, $i, 1) + 
				       $self->{'args'}->get_arg_values($calc, $i, 2) + 1) );
    $self->add_volatile_arg_dependency(5, 2 * ($self->{'args'}->get_arg_values($calc, $i, 1) + 
				       $self->{'args'}->get_arg_values($calc, $i, 2) + 1) );

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i) );

    my $sumval = 0;
    my $sumabs = 0;
    my $mom = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 2);

    for (my $n = 0; $n < $nb; $n++) {
      my $h = $self->{'args'}->get_arg_values($calc, $i-$n, 3);
      my $l = $self->{'args'}->get_arg_values($calc, $i-$n, 4);
      my $h2 = $self->{'args'}->get_arg_values($calc, $i-$n-$mom, 3);
      my $l2 = $self->{'args'}->get_arg_values($calc, $i-$n-$mom, 4);
      my $h5 = $self->{'args'}->get_arg_values($calc, $i-$n-$nb, 3);
      my $l5 = $self->{'args'}->get_arg_values($calc, $i-$n-$nb, 4);
      my $h6 = $self->{'args'}->get_arg_values($calc, $i-$n-$nb-1, 3);
      my $l6 = $self->{'args'}->get_arg_values($calc, $i-$n-$nb-1, 4);
      my $c7 = $self->{'args'}->get_arg_values($calc, $i-$n-$nb-$mom, 5);
      my $c8 = $self->{'args'}->get_arg_values($calc, $i-$n-$nb-$mom-1, 5);

      if ( ( ($h>=$l5 || $h>=$l6) && ($l<=$h5 || $l<=$h6) ) ||
	   ( ($h2>=$c7 || $h2>=$c8) && ($l2<=$c7 || $l2<=$c8) ) ) {
	$sumval += ($h - $h2 + $l - $l2);
	$sumabs += abs($h-$h2) + abs($l-$l2);
      }
    }

    if ($sumabs == 0) {
      $sumabs += 0.00001;
    }

    my $erg = 100 * $sumval / $sumabs;

    $indic->set($name, $i, $erg);

}

1;
