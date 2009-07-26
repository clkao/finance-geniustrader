package GT::Brokers::Zebank;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::Brokers;
use GT::Eval;
use GT::Conf;

@NAMES = ("Zebank[#1]");
@ISA = qw(GT::Brokers);

=head1 GT::Brokers::Zebank

=head2 Overview

This module will calculate all commissions and charges according to
Zebank rules.

=head2 Calculation

0,45 % TTC / order with a minimum of 9 EUR

Free return if buy & sell during the same day.

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
    my $commission = 0;
    
    if ( (defined($order->quantity) && $order->quantity) and
         (defined($order->price) && $order->price) ) {

        my $investment = $order->quantity * $order->price;
	
	# Calculate the 0.45 % TTC commission with a minimum of 9 EUR
	$commission = sprintf("%.2f", ($investment * 0.45 / 100));
	$commission = 9 if ($commission < 9);

	# TODO : Free return if buy & sell during the same day.
	
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
