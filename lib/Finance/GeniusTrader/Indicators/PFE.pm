package GT::Indicators::PFE;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::ArgsTree;
use GT::Indicators;
use GT::Indicators::EMA;

@ISA = qw(GT::Indicators);
@NAMES = ("PFE[#*]");
@DEFAULT_ARGS = (10,5,2,1,"{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::PFE - Polarized Fractal Efficiency

=head1 DESCRIPTION 


=head2 Parameters

=over 

=item Period (default 10)

The first argument is the period used to calculed the average.

=item Period 2 (default 5)

Period in which the EMA is calculated.

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
    my $pfe = "{I:PFEraw " . $self->{'args'}->get_arg_names(1) . " " .$self->{'args'}->get_arg_names(3) . " " .
      $self->{'args'}->get_arg_names(4) . " " . $self->{'args'}->get_arg_names(5) . "}";

    $self->{'ema'} = GT::Indicators::EMA->new([$self->{'args'}->get_arg_names(2), $pfe]);
    
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name(0);
    my $length = $self->{'args'}->get_arg_values($calc, $i, 1);

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(5, $length);
    $self->add_volatile_indicator_dependency($self->{'ema'}, $length);
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $pfe = $calc->indicators->get($self->{'ema'}->get_name(0), $i);
    $indic->set($name, $i, $pfe);
}

1;
