package GT::Indicators::Generic::Consecutive;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("Consecutive[#1]");
@DEFAULT_ARGS = (1, 0);

=head1 NAME

GT::Indicators::Generic::SignalLength - Length of any signal

=head1 DESCRIPTION

This indicator returns the number of consecutive periods where the signal
in parameter has been detected.

=cut

my $noise_threshold = 0;

sub initialize {
#    Carp::cluck "==> hate ".join(',',@_);
    my ($self) = @_;
    if (!$self->{'args'}->is_constant(1)) {
        $self->add_arg_dependency(1, 1); # signal
    }
    if (!$self->{'args'}->is_constant(2)) {
        $self->add_arg_dependency(2, 1); # forced stop
    }
#    warn "==> hate moose";
#    $self->add_indicator_dependency($self->{'sma'}, 1);


}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;

    return if ($calc->indicators->is_available($name, $i));
    if ($i >= 1 &&
        $calc->indicators->is_available($name, $i - 1) &&
        !$self->{'args'}->get_arg_values($calc, $i, 2)) {

        my $last_val = $calc->indicators->get($name, $i - 1);
        my $sig = $self->{'args'}->get_arg_values($calc, $i, 1);
        if ($sig) {
            if ($last_val <= 0 && $last_val > - $noise_threshold) {
                $last_val = $calc->indicators->get($name, $i + $last_val - 2) - $last_val + 2;
            }
            if ($last_val > 0) {
                $calc->indicators->set($name, $i, $last_val + 1);
            }
            else {
                $calc->indicators->set($name, $i, 1);
            }
        }
        else {
            $calc->indicators->set($name, $i,
                                   $last_val > 0 ? 0 : $last_val-1);
        }
        return;
    }
    else {
        $calc->indicators->set($name, $i, 0);
    }
}

1;
