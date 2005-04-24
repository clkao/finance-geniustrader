package GT::Systems::ADX2;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Carp::Datum;
use GT::Prices;
use GT::Systems;
use GT::Indicators::ADX;
use GT::Indicators::ADXR;

@ISA = qw(GT::Systems);
@NAMES = ("ADX2[#1]");
@DEFAULT_ARGS = (14);

=pod

=head1 Trend following system 2

=cut

sub initialize {
    my ($self) = @_;
    $self->{'allow_multiple'} = 0;
}

sub precalculate_interval {
    DFEATURE my $f;
    my ($self, $calc, $first, $last) = @_;
    if ($self->{'args'}->is_constant()) {
	my $period = $self->{'args'}->get_arg_constant(1);
	my $adx = GT::Indicators::ADX->new([$period]);
	$adx->calculate_interval($calc, $first, $last);
	my $adxr = GT::Indicators::ADXR->new([$period]);
	$adxr->calculate_interval($calc, $first, $last);
    }
    return DVOID;
}

sub long_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;

    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $adx = GT::Indicators::ADX->new([$period]);
    my $adx_name = $adx->get_name(0);
    my $positive_di_name = $adx->get_name(1);
    my $negative_di_name = $adx->get_name(2);
    my $adxr = GT::Indicators::ADXR->new([$period]);
    my $adxr_name = $adxr->get_name;

    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency($adx, 2);
    $self->add_volatile_indicator_dependency($adxr, 1);

    return DVAL 0 if (!$self->check_dependencies_interval($calc, $i - 1, $i));

    if (($calc->indicators->get($positive_di_name, $i) >
	 $calc->indicators->get($negative_di_name, $i))
	&&
	($calc->indicators->get($adx_name, $i - 1) <
	 $calc->indicators->get($adx_name, $i))
	&&
	($calc->indicators->get($adxr_name, $i) > 25)
	)
    {
	return DVAL 1;
    }
    return DVAL 0;
}

sub short_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;

    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $adx = GT::Indicators::ADX->new([$period]);
    my $adx_name = $adx->get_name(0);
    my $positive_di_name = $adx->get_name(1);
    my $negative_di_name = $adx->get_name(2);
    my $adxr = GT::Indicators::ADXR->new([$period]);
    my $adxr_name = $adxr->get_name;

    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency($adx, 2);
    $self->add_volatile_indicator_dependency($adxr, 1);

    return DVAL 0 if (!$self->check_dependencies_interval($calc, $i - 1, $i));

    if (($calc->indicators->get($positive_di_name, $i) <
         $calc->indicators->get($negative_di_name, $i))
        &&
        ($calc->indicators->get($adx_name, $i - 1) <
         $calc->indicators->get($adx_name, $i))
        &&
        ($calc->indicators->get($adxr_name, $i) > 25)
        )
    {
	return DVAL 1;
    }
    return DVAL 0;
}
