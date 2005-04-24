package GT::Systems::AlwaysInTheMarket;

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Carp::Datum;
use GT::Systems;

@ISA = qw(GT::Systems);
@NAMES = ("AlwaysInTheMarket");

=head1 AlwaysInTheMarket Trading System

=head2 Overview

This system will generate every time it is called a long and a short signal.

=head2 Examples

To set up a Buy And Hold strategy :
--system="AlwaysInTheMarket" --close-strategy="NeverClose" --trade-filter="LongOnly" --trade-filter="OneTrade"

To set up a Short And Hold strategy :
--system="AlwaysInTheMarket" --close-strategy="NeverClose" --trade-filter="ShortOnly" --trade-filter="OneTrade"

=head2 Note

In which way is a BuyAndHold or a ShortAndHold system usefull ?

The main purpose is to run the system on a list of securities, in order to
get the portfolio performance. Let's try to catch indices performance with
just a few stocks and beat the market only with money-management ! Welcome
to the world of portfolio selection and portfolio optimization.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub long_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    
    return DVAL 1;
}

sub short_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    
    return DVAL 1;
}

1;
