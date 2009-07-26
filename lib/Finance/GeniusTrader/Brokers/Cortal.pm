package GT::Brokers::Cortal;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::Brokers;
use GT::Eval;
use GT::Conf;

@NAMES = ("Cortal[#1]");
@ISA = qw(GT::Brokers);

=head1 GT::Brokers::Cortal

=head2 Overview

This module will calculate all commissions and charges according to
Cortal rules.

=head2 Calculation

For orders "A tout prix" and "prix du marché" :

5 Euros HT / order up to 1500 Euros
10 Euros HT / order up to 3000 Euros
0.30 % / order up to 100 000 Euros + 0.10 % / after

For other orders :

7.5 Euros HT / order up to 1500 Euros
12.5 Euros HT / order up to 3000 Euros
0.50 % / order up to 100 000 Euros + 0.10 % / after

Annual account charge (30/06 and 31/12) :

Up to 150 000 Euros : 0.15 % HT of the portfolio value, after 0 %
Minimum : 12 Euros HT.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
    my $option = "Découverte";
    
    if (GT::Conf::get("Brokers::SelfTrade::Forfait")) {
	$option = GT::Conf::get("Brokers::SelfTrade::Forfait");
    }
    
    my $self = { 'args' => defined($args) ? $args : [ $option ] };

    $args->[0] = $option if (! defined($args->[0]));

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

=head2 $broker->calculate_order_commission($order)

Return the amount of money ask by the broker for the given order.

=cut

sub calculate_order_commission {
    my ($self, $order) = @_;
#    my $forfait = $self->{'args'}[0];
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
	
	if ( ((defined($order->is_type_market_price)) && ($order->is_type_market_price)) or
	     ((defined($order->is_type_stop)) && ($order->is_type_stop)) ) {
	    
	    # For "A tout prix" and "Prix du marché" orders

	    if ($investment < 1500) {
		$commission = sprintf("%.2f", (5.00 * $TVA));
	    }
	    if ($investment < 3000 and $investment > 1500) {
		$commission = sprintf("%.2f", (10.00 * $TVA));
	    }
	    if ($investment < 100000 and $investment > 3000) {
		$commission = sprintf("%.2f", ($investment * 0.30 / 100 * $TVA));
	    }
	    if ($investment > 100000) {
		$commission = sprintf("%.2f", (100000 * 0.30 / 100 * $TVA));
		$commission += sprintf("%.2f", (($investment - 100000) * 0.10 / 100 * $TVA));
	    }

	} else {

	    # For other type of orders
	    
	    if ($investment < 1500) {
		$commission = sprintf("%.2f", (7.50 * $TVA));
	    }
	    if ($investment < 3000 and $investment > 1500) {
		$commission = sprintf("%.2f", (12.50 * $TVA));
	    }
	    if ($investment < 100000 and $investment > 3000) {
		$commission = sprintf("%.2f", ($investment * 0.50 / 100 * $TVA));
	    }
	    if ($investment > 100000) {
		$commission = sprintf("%.2f", (100000 * 0.50 / 100 * $TVA));
		$commission += sprintf("%.2f", (($investment - 100000) * 0.10 / 100 * $TVA));
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
	
	return $commission if ($commission != 0);;
    }
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
