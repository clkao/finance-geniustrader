package Finance::GeniusTrader::Brokers::InteractiveBrokers;

# Copyright 2003 Olaf Dietsche
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::Brokers;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::Conf;

@NAMES = ("InteractiveBrokers[#1]", "IB[#1]");
@ISA = qw(Finance::GeniusTrader::Brokers);

=head1 Finance::GeniusTrader::Brokers::InteractiveBrokers

=head2 Overview

This module will calculate all commissions and charges according to
InteractiveBrokers rules.

=head2 Calculation

Current calculation for InteractiveBrokers at:
L<http://www.interactivebrokers.com/index.html?html/retailAccount/fees.html~top.body>

Germany XETRA/IBIS:
0,1% of stock value, minimum of 4 EUR, maximum of 29 EUR

Switzerland:
0,1% of stock value, minimum of 10 CHF + 0.07% Stamp Tax

UK:
0,1% of stock value, minimum of 5 GBP + 0.5% UK Stamp Tax on purchase

Ireland:
same as UK, but 1% Irish Stamp Tax

US:
USD 0.01 / share, up to 500 shares
USD 0.005 / share, for 501th share and up
minimum of 1 USD

Options and futures commissions are not considered.

No annual charge.

=head2 Parameters

The first parameter could be initialized to :

'de' => Germany Xetra,
'ch' => Switzerland,
'ie' => Ireland,
'uk' => United Kingdom,
'us' => US Markets

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
    Finance::GeniusTrader::Conf::default('Brokers::InteractiveBrokers::Market', 'de');
    my $option = Finance::GeniusTrader::Conf::get('Brokers::InteractiveBrokers::Market');
    my $self = { 'args' => defined($args) ? $args : [$option] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

=head2 $broker->calculate_order_commission($order)

Return the amount of money ask by the broker for the given order.

=cut

sub calculate_order_commission_percentage {
    my($self, $order, $percent, $min, $max) = @_;
    my $commission = 0;

    if ((defined($order->quantity) && $order->quantity) and
	(defined($order->price) && $order->price)) {
	my $investment = $order->quantity * $order->price;
	$commission = sprintf("%.2f", $investment * $percent);
	$commission = $min if ($min and $commission < $min);
	$commission = $max if ($max and $commission > $max);
	return $commission if ($commission != 0);
    }
}

sub calculate_order_commission_de {
    my ($self, $order) = @_;
    return $self->calculate_order_commission_percentage($order, 0.1 / 100, 4, 29);
}

sub calculate_order_commission_ch {
    my ($self, $order) = @_;
    my $commission = $self->calculate_order_commission_percentage($order, 0.1 / 100, 10);
    $commission += $commission * 0.07 / 100;
    return $commission if ($commission != 0);
}

sub calculate_order_commission_ie {
    my ($self, $order) = @_;
    my $commission = $self->calculate_order_commission_percentage($order, 0.1 / 100, 5);
    $commission += $commission * 1.0 / 100 if ($order->is_buy_order());
    return $commission if ($commission != 0);
}

sub calculate_order_commission_uk {
    my ($self, $order) = @_;
    my $commission = $self->calculate_order_commission_percentage($order, 0.1 / 100, 5);
    $commission += $commission * 0.5 / 100 if ($order->is_buy_order());
    return $commission if ($commission != 0);
}

sub calculate_order_commission_us {
    my ($self, $order, $min) = @_;
    my $quantity = $order->quantity;
    my $commission = 0;

    if ($quantity) {
	if ($quantity > 500) {
	    $commission = sprintf("%.2f", ($quantity - 500) * 0.005);
	    $quantity = 500;
	}

	$commission += $quantity * 0.01;
	$commission = 1 if ($min and $commission < 1);
	return $commission if ($commission != 0);
    }
}

sub calculate_order_commission {
    my ($self, $order) = @_;
    my $market = $self->{args}->[0];
    return $self->calculate_order_commission_de($order) if ($market eq 'de');
    return $self->calculate_order_commission_ch($order) if ($market eq 'ch');
    return $self->calculate_order_commission_ie($order) if ($market eq 'ie');
    return $self->calculate_order_commission_uk($order) if ($market eq 'uk');
    return $self->calculate_order_commission_us($order) if ($market eq 'us');

    die "$market: unknown market";
}

=head2 $broker->calculate_annual_account_charge($portfolio, $year)

Return the amount of money ask by the broker for the given year
according to the given portfolio, which is 0 EUR.

=cut

sub calculate_annual_account_charge {
    my ($self, $portfolio, $year) = @_;
    return 0;
}

1;
