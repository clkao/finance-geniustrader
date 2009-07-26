package Finance::GeniusTrader::Brokers::Logitelnet;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# submitted by sam godbillot 26 nov 07

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::Brokers;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::Conf;

@NAMES = ("Logitelnet[#1]");
@ISA = qw(Finance::GeniusTrader::Brokers);

=head1 Finance::GeniusTrader::Brokers::Logitelnet

=head2 Overview

This module will calculate all commissions and charges according to
Logitelnet (Societe Generale) rules

=head2 Calculation

0.54%  / order < 8000 Euros, 8.90 Euros minimum
0.44%  / 8000  <= order < 15000 Euros
0.34 % / order up to 15000 Euros 

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
    
    my $self = { 'args' => defined($args) ? $args : [] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

=head2 $broker->calculate_order_commission($order)

Return the amount of money ask by the broker for the given order.

=cut

sub calculate_order_commission {
    my ($self, $order) = @_;
    my $investment;
    my $TVA = (1 + 19.6 / 100);
    my $commission = 0;

    # Override $TVA if Brokers::TVA is already defined in the user
    # configuration file

    if (Finance::GeniusTrader::Conf::get("Brokers::TVA")) {
       $TVA = (1 + Finance::GeniusTrader::Conf::get("Brokers::TVA") / 100);
    }

    if ( (defined($order->quantity) && $order->quantity) and (defined($order->price) && $order->price) ) {
        $investment = $order->quantity * $order->price;
        if ($investment < 8000) {
            $commission = sprintf("%.2f", ($investment*0.0054 * $TVA));
            if ($commission < 8.9) {
                $commission=8.9;
            }
        }
        if ($investment <= 8000 and $investment < 15000) {
            $commission = sprintf("%.2f", ($investment*0.0044 * $TVA));
        }
        if ($investment < 100000 and $investment > 3000) {
            $commission = sprintf("%.2f", ($investment*0.0034 * $TVA));
        }
    }

    # Add the "Impot de bourse"
    my $impot_de_bourse;
    if ($investment > 7830) {
        if ($investment < 153000) {
            $impot_de_bourse = ($investment-7830) * 0.30 / 100;
        }
        else {
            $impot_de_bourse = ($investment-7830) * 0.15 / 100;
        }
        $commission += $impot_de_bourse;
    }

    return $commission if ($commission != 0);;
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
