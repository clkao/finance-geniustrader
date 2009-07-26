package Finance::GeniusTrader::Systems::MacdDiff;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Systems;
use Finance::GeniusTrader::Signals::Systems::MacdDiff;
use Finance::GeniusTrader::Indicators::ATR;

@ISA = qw(Finance::GeniusTrader::Systems);
@NAMES = ("MacdDiff");

=pod

=head1 Trend following system

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [3] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;

    $self->{'macddiff'} = Finance::GeniusTrader::Signals::Systems::MacdDiff->new([12,26,4]);
    $self->{'atr'} = Finance::GeniusTrader::Indicators::ATR->new([ $self->{'args'}[0] ]);

    $self->add_signal_dependency($self->{'macddiff'}, 1);
    $self->add_indicator_dependency($self->{'atr'}, 1);
    $self->add_prices_dependency(1);
}


sub long_signal {
    my ($self, $calc, $i) = @_;
    
    return 0 if (!$self->check_dependencies($calc, $i));
    
    if ($calc->signals->get($self->{'macddiff'}->get_name(1), $i))
    {
	return 1;
    }
    return 0;
}

sub short_signal {
    my ($self, $calc, $i) = @_;

    return 0 if (!$self->check_dependencies($calc, $i));
    
    if ($calc->signals->get($self->{'macddiff'}->get_name(0), $i))
    {
	return 1;
    }
    return 0;
}
