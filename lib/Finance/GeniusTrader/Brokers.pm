package Finance::GeniusTrader::Brokers;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT %OBJECT_REPOSITORY);

require Exporter;
use Finance::GeniusTrader::Dependency;
use Finance::GeniusTrader::Serializable;

@ISA = qw(Exporter Finance::GeniusTrader::Dependency Finance::GeniusTrader::Serializable);
@EXPORT = qw(&build_object_name &manage_object);

use Finance::GeniusTrader::Registry;
#ALL#  use Log::Log4perl qw(:easy);

=head1 NAME

Finance::GeniusTrader::Brokers - A module for calculating broker's fee & commissions

=head1 DESCRIPTION

Brokers rules are used to calculate commissions for each buy/sell order,
as well as annual account charge.

=over

=item C<< $broker->calculate_order_commission($order) >>

Return the amount of money ask by the broker for the given order.

=cut
sub calculate_order_commission {
    my ($self, $order) = @_;

    return;
}

=item C<< $broker->calculate_annual_account_charge($portfolio, $year) >>

Return the amount of money ask by the broker for the given year
according to the given portfolio.

=cut
sub calculate_annual_account_charge {
    my ($self, $portfolio, $year) = @_;

    return;
}

# Default initialize that does nothing
sub initialize { 1 }

# Finance::GeniusTrader::Registry functions
sub get_registered_object {
    Finance::GeniusTrader::Registry::get_registered_object(\%OBJECT_REPOSITORY, @_);
}
sub register_object {
    Finance::GeniusTrader::Registry::register_object(\%OBJECT_REPOSITORY, @_);
}
sub get_or_register_object {
    Finance::GeniusTrader::Registry::get_or_register_object(\%OBJECT_REPOSITORY, @_);
}
sub manage_object {
    Finance::GeniusTrader::Registry::manage_object(\%OBJECT_REPOSITORY, @_);
}

=pod

=back

=cut
1;
