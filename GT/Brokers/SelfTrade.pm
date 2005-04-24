package GT::Brokers::SelfTrade;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::Brokers;
use GT::Eval;
use GT::Conf;
use Carp::Datum;

@NAMES = ("SelfTrade[#1]");
@ISA = qw(GT::Brokers);

=head1 GT::Brokers::SelfTrade

=head2 Overview

This module will calculate all commissions and charges according to
SelfTrade rules.

=head2 Calculation

Forfait Découverte : 6.5 Euros HT / order up o 3000 Euros + 0.30 % HT after

Forfait Intégral : 14.95 Euros HT / order up to 10000 Euros + 0.15 % HT after

For both options, there's no annual account charge !

=head2 Parameters

The first parameter could be initialized to :
"Découverte" => Forfait Découverte
"Intégral" => Forfait Intégral

=cut

sub new {
    DFEATURE my $f, "new Broker";
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
    my $option = "Découverte";
    
    if (GT::Conf::get("Brokers::SelfTrade::Forfait")) {
	$option = GT::Conf::get("Brokers::SelfTrade::Forfait");
    }
    
    my $self = { 'args' => defined($args) ? $args : [ $option ] };

    $args->[0] = $option if (! defined($args->[0]));

    return DVAL manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

=head2 $broker->calculate_order_commission($order)

Return the amount of money ask by the broker for the given order.

=cut

sub calculate_order_commission {
    DFEATURE my $f;
    my ($self, $order) = @_;
    my $forfait = $self->{'args'}[0];
    my $TVA = (1 + 19.6 / 100);
    my $commission = 0;
    
    # Override $TVA if Brokers::TVA is already defined in the user
    # configuration file
    
    if (GT::Conf::get("Brokers::TVA")) {
	$TVA = (1 + GT::Conf::get("Brokers::TVA") / 100);
    }
    
    if ( (defined($order->quantity) && $order->quantity) and
         (defined($order->price) && $order->price) ) {

        my $investment = $order->quantity * $order->price;
	
	if ($forfait eq "Découverte") {
            
	    if ($investment < 3000) {
                $commission = sprintf("%.2f", (6.50 * $TVA));
            } else {
                $commission = sprintf("%.2f", (6.50 * $TVA + (($investment - 3000) * 0.30 / 100 * $TVA)));
            }
        }
	
	if ($forfait eq "Intégral") {

	    if ($investment < 10000) {
		$commission = sprintf("%.2f", (14.95 * $TVA));
	    } else {
		$commission = sprintf("%.2f", (14.95 * $TVA + (($investment - 10000) * 0.15 / 100 * $TVA)));
	    }
	}
	
	# Add the "Impôt de bourse"
	my $impot_de_bourse = $investment * 0.30 / 100;
	my $abattement = 150 / 6.55957;
	my $plafond = 4000 / 6.55957;
	
	if ($impot_de_bourse > $abattement) {
	    $impot_de_bourse = $plafond if (($impot_de_bourse - $abattement) > $plafond);
	    $commission += sprintf("%.2f", ($impot_de_bourse - $abattement));
	}
	
	return DVAL $commission if ($commission != 0);;
    }
}

=head2 $broker->calculate_annual_account_charge($portfolio, $year)

Return the amount of money ask by the broker for the given year
according to the given portfolio.

=cut

sub calculate_annual_account_charge {
    DFEATURE my $f;
    my ($self, $portfolio, $year) = @_;

    return DVAL 0;

}

1;
