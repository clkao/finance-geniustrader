package Finance::GeniusTrader::Systems::AlwaysInTheMarket;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Systems;

@ISA = qw(Finance::GeniusTrader::Systems);
@NAMES = ("AlwaysInTheMarket");

=head1 AlwaysInTheMarket Trading System

=head2 Overview

This system will generate every time it is called a long and a short signal.

=head2 Examples

To set up a Buy And Hold strategy :
SY:AlwaysInTheMarket|CS:NeverClose|TF:LongOnly|TF:OneTrade

To set up a Short And Hold strategy :
SY:AlwaysInTheMarket|CS:NeverClose|TF:ShortOnly|TF:OneTrade

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
    my ($self, $calc, $i) = @_;
    
    return 1;
}

sub short_signal {
    my ($self, $calc, $i) = @_;
    
    return 1;
}

1;
