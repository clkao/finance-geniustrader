package Finance::GeniusTrader::Brokers::Dubus;

# Copyright 2005 Yannick Tournedouet
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# v1.0 : Initial version

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::Brokers;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::Conf;

@NAMES = ("Dubus[#1]");
@ISA = qw(Finance::GeniusTrader::Brokers);

=head1 Finance::GeniusTrader::Brokers::Dubus

=head2 Overview

This module will calculate all commissions and charges according to
Dubus rules.

=head2 Calculation

Tarif Normal : 

	4.9 Euros HT / order up o 2000 Euros + 0.30 % HT after (since 26/05/2005 4.9 € instead of 4 €)
	
	Account charge : 0.37 € HT (min 100 €)

Tarif Forfait : 

	4.9 Euros HT / order up o 2000 Euros + 0.30 % HT after (since 26/05/2005 4.9 € instead of 4 €)
	15 € Euros HT / order up to 30000 Euros
	25 € Euros HT / order up to 75000 Euros
	50 € Euros HT / more than 75000 Euros
	
	Account charge : 76 €

=head2 Parameters

The first parameter could be initialized to :
"Normal" => Tarif Normal
"Forfait" => Tarif Forfait

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
    my $option = "Normal";
    
    if (Finance::GeniusTrader::Conf::get("Brokers::Dubus::Tarif")) {
		$option = Finance::GeniusTrader::Conf::get("Brokers::Dubus::Tarif");
    }

    my $self = { 'args' => defined($args) ? $args : [ $option ]};

    $args->[0] = $option if (! defined($args->[0]));

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

=head2 $broker->calculate_order_commission($order)

Return the amount of money ask by the broker for the given order.

=cut

sub calculate_order_commission {
    my ($self, $order) = @_;
    my $forfait = $self->{'args'}[0];
    my $TVA = (1 + 19.6 / 100);
    my $commission = 0;
    my $account = "";    
    
    # Override $TVA if Brokers::TVA is already defined in the user
    # configuration file
    
    if (Finance::GeniusTrader::Conf::get("Brokers::TVA")) {
		$TVA = (1 + Finance::GeniusTrader::Conf::get("Brokers::TVA") / 100);
    }
	
	# get the account : PEA or simple account
    if (Finance::GeniusTrader::Conf::get("Brokers::Account")) {
		$account = Finance::GeniusTrader::Conf::get("Brokers::Account");
    }
    
    if ( (defined($order->quantity) && $order->quantity) and
         (defined($order->price) && $order->price) ) {

        my $investment = $order->quantity * $order->price;
	
	if ($forfait eq "Normal") {
            
	    if ($investment <= 2000) {
                $commission = sprintf("%.2f", (6.9 * $TVA));
        } else {
                $commission = sprintf("%.2f", (($investment * 0.30) / 100 * $TVA));
	    }    
    }
	
	if ($forfait eq "Forfait") {

	    if ($investment <= 2000) {
			$commission = sprintf("%.2f", (6.9 * $TVA));
	    } elsif ($investment <= 30000) {
			$commission = sprintf("%.2f", (15 * $TVA));
	    } elsif ($investment <= 75000) {
			$commission = sprintf("%.2f", (25 * $TVA));
	    } elsif ($investment > 75000) {
			$commission = sprintf("%.2f", (50 * $TVA));			
	    }
	}
	
	# Add the "Impôt de bourse"
	if ($account ne "PEA") {
		my $impot_de_bourse = $investment * 0.30 / 100;
		my $abattement = 150 / 6.55957;
		my $plafond = 4000 / 6.55957;
	
		if ($impot_de_bourse > $abattement) {
		    $impot_de_bourse = $plafond if (($impot_de_bourse - $abattement) > $plafond);
	    	$commission += sprintf("%.2f", ($impot_de_bourse - $abattement));
		}
    }
	
	return $commission if ($commission != 0);
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
