package GT::Indicators::KAMA;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("KAMA[#*]");
@DEFAULT_ARGS = (21, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::KAMA - Perry Kaufmanns Adaptive Moving Average

=head1 DESCRIPTION 

This Indicator was developed by Perry Kaufmann and presented in the 
book "Trading Systems and Methods, 3rd Ed." in 1998. The KAMA is
automatically adapted to the volatility of the market. 

The interpretation is similar to the classic SMA. 

=over 

=item Period (default 21)

The first argument is the period used to calculed the average.

=back

=head2 Creation

 GT::Indicators::KAMA->new()
 GT::Indicators::KAMA->new([10])

=cut

sub initialize {
    my ($self) = @_;
    if ($self->{'args'}->is_constant(1) && ($self->{'args'}->get_nb_args() > 1)) {
	$self->add_arg_dependency(2, $self->{'args'}->get_arg_constant(1));
    }
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;
    my $kama = 0;

    return if (! defined($nb));

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $nb);

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $efratio = 1;
    my $noise = 0;
    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	$noise += abs( $self->{'args'}->get_arg_values($calc, $n-1, 2) -
		       $self->{'args'}->get_arg_values($calc, $n, 2));
    }
    my $signal = abs( $self->{'args'}->get_arg_values($calc, $i-$nb+1, 2) -
		      $self->{'args'}->get_arg_values($calc, $i, 2) );

    if ($noise != 0)
    {
	$efratio = $signal / $noise;
    }
    my $fastsc = 2/(2+1);
    my $slowsc = 2/(30+1);
    my $ssc = $efratio * ($fastsc-$slowsc) + $slowsc;
    my $smooth = $ssc * $ssc;

    my $ama;
    if ($calc->indicators->is_available($name, $i-1))
    {
	$ama = $calc->indicators->get($name, $i-1);
	$kama = $ama + $smooth * ($self->{'args'}->get_arg_values($calc, $i, 2)-$ama);
    }
    else {
	$kama = $self->{'args'}->get_arg_values($calc, $i-1, 2); 
    }

    $calc->indicators->set($name, $i, $kama);
}

