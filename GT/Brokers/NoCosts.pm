package GT::Brokers::NoCosts;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::Brokers;
use GT::Eval;
use GT::Conf;
use Carp::Datum;

@NAMES = ("NoCosts[]");
@ISA = qw(GT::Brokers);

=head1 GT::Brokers::NoCosts

=head2 Overview

This module will calculate no commissions or charges.

=cut

sub new {
    DFEATURE my $f, "new Broker";
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
    my $self = {};

    return DVAL manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

=head2 $broker->calculate_order_commission($order)

Return the amount of money ask by the broker for the given order.

=cut

sub calculate_order_commission {
    my ($self, $order) = @_;
    return 0;
}

=head2 $broker->calculate_annual_account_charge($portfolio, $year)

Return the amount of money ask by the broker for the given year
according to the given portfolio.

=cut

sub calculate_annual_account_charge {
    my ($self, $portfolio, $year) = @_;
    return 0;
}

1;
