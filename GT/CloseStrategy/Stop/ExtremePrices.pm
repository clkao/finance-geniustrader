package GT::CloseStrategy::Stop::ExtremePrices;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::CloseStrategy;
use GT::Prices;
use Carp::Datum;
use GT::Indicators::MIN;
use GT::Indicators::MAX;

@ISA = qw(GT::CloseStrategy);
@NAMES = ("ExtremePrices[#1,#2,#3]");
@DEFAULT_ARGS = (20, 1, "{I:Prices CLOSE}");

=head1 GT::CloseStrategy::Stop::ExtremePrices

This strategy closes the position once the prices have crossed up the
highest high in a short position and crossed down the highest low in a
logn position.

=cut

sub initialize {
    my ($self) = @_;

    $self->{'min'} = GT::Indicators::MIN->new([ $self->{'args'}->get_arg_names(1) ]);
    $self->{'max'} = GT::Indicators::MAX->new([ $self->{'args'}->get_arg_names(1) ]);

    $self->add_indicator_dependency($self->{'min'}, 1);
    $self->add_indicator_dependency($self->{'max'}, 1);
    $self->add_prices_dependency(1);
}

sub get_indicative_long_stop {
    DFEATURE my $f;
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;

    return DVOID if (! $self->check_dependencies($calc, $i));

    my $percentage = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $lowest_low = $calc->indicators->get($self->{'min'}->get_name, $i);

    return DVAL ($lowest_low * (1 - $percentage / 100));
}

sub get_indicative_short_stop {
    DFEATURE my $f;
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;

    return DVOID if (! $self->check_dependencies($calc, $i));

    my $percentage = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $highest_high = $calc->indicators->get($self->{'max'}->get_name, $i);

    return DVAL ($highest_high * (1 + $percentage / 100));
}

sub long_position_opened {
    DFEATURE my $f;
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return DVOID;
}

sub short_position_opened {
    DFEATURE my $f;
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return DVOID;
}

sub manage_long_position {
    DFEATURE my $f;
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return DVOID if (! $self->check_dependencies($calc, $i));

    my $percentage = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $lowest_low = $calc->indicators->get($self->{'min'}->get_name, $i);
    $position->set_stop($lowest_low * (1 - $percentage / 100));

    return DVOID;
}

sub manage_short_position {
    DFEATURE my $f;
    my ($self, $calc, $i, $position, $ps_manager, $sys_manager) = @_;

    return DVOID if (! $self->check_dependencies($calc, $i));

    my $percentage = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $highest_high = $calc->indicators->get($self->{'max'}->get_name, $i);
    $position->set_stop($highest_high * (1 + $percentage / 100));

    return DVOID;
}

