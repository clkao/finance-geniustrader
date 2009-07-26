package Finance::GeniusTrader::Indicators::PFEraw;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

# ras hack based on version dated 24 Apr 2005 2099 bytes
# $Id$

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::ArgsTree;
use Finance::GeniusTrader::Indicators;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("PFEraw[#*]");
@DEFAULT_ARGS = (10,2,1,"{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::PFE - Polarized Fractal Efficiency

=head1 DESCRIPTION 


=head2 Parameters

=over 

=item Period (default 10)

The first argument is the period used to calculate the average.

=item Exponent (default 2)

=item Correction-Factor (default 1)

Set this factor to 200 for values > 1000

=item Datasource

=back

=head2 Creation


=head2 Link


=cut

sub initialize {
    my ($self) = @_;
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name(0);
    my $length = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $exp = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $factor = $self->{'args'}->get_arg_values($calc, $i, 3);

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(4, $length);
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $pfe = $self->{'args'}->get_arg_values($calc, $i, 4)
              - $self->{'args'}->get_arg_values($calc, $i-$length, 4);
    $pfe = sqrt( ($pfe/$factor)**$exp + $length**$exp );

    my $c2c = 0;
    for (my $counter=$i-$length+1; $counter<=$i; $counter++) {
        my $diff = $self->{'args'}->get_arg_values($calc, $counter, 4)
                   - $self->{'args'}->get_arg_values($calc, $counter-1, 4);
        $c2c += sqrt ( ($diff/$factor)**$exp + 1 );
    }

    my $arg = $self->{'args'}->get_arg_values($calc, $i, 4)
              - $self->{'args'}->get_arg_values($calc, $i-$length, 4);
    if ( $arg > 0 ) {
        $pfe = ( $pfe/$c2c*100 );
    } else {
        $pfe = ( -$pfe/$c2c*100 );
    }

    $indic->set($name, $i, $pfe);
}

1;
