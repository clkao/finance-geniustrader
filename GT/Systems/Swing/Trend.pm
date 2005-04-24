package GT::Systems::Swing::Trend;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Carp::Datum;
use GT::Prices;
use GT::Systems;
use GT::Signals::Swing::Trend;
use GT::Signals::Swing::TrendEnding;

@ISA = qw(GT::Systems);
@NAMES = ("Trend");

=pod

=head1 Trend following system

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { "args" => [] };

    return manage_object(\@NAMES, $self, $class, [ ], "");
}

sub initialize {
    my ($self) = @_;

    $self->{'trend'} = GT::Signals::Swing::Trend->new;
    $self->{'trendending'} = GT::Signals::Swing::TrendEnding->new;

    $self->add_signal_dependency($self->{'trend'}, 1);
    $self->add_signal_dependency($self->{'trendending'}, 1);
    $self->add_prices_dependency(1);
}


sub long_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    
    return DVAL 0 if (!$self->check_dependencies($calc, $i));
    
    if ($calc->signals->get($self->{'trend'}->get_name(1), $i) ||
	$calc->signals->get($self->{'trendending'}->get_name(1), $i))
    {
	return DVAL 1;
    }
    return DVAL 0;
}

sub short_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;

    return DVAL 0 if (!$self->check_dependencies($calc, $i));
    
    if ($calc->signals->get($self->{'trend'}->get_name(0), $i) ||
	$calc->signals->get($self->{'trendending'}->get_name(0), $i))
    {
	return DVAL 1;
    }
    return DVAL 0;
}
