package GT::Brokers::Usaa;
## Usaa.pm
## $Id$
## Copyright (C) 2003 Chris Beggy

## Author: Chris Beggy <chrisb@kippona.com>
## Maintainer: Chris Beggy <chrisb@kippona.com>
## Adapted by:
## Created: 23 Jun 2003
## Version: 0.1
## Keywords: geniustrader
##

## This program is free software; you can redistribute it and/or
## modify it under the terms of the GNU General Public License as
## published by the Free Software Foundation; either version 2 of
## the License, or (at your option) any later version.

## This program is distributed in the hope that it will be
## useful, but WITHOUT ANY WARRANTY; without even the implied
## warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR
## PURPOSE.  See the GNU General Public License for more details.

## You should have received a copy of the GNU General Public
## License along with this program; if not, write to the Free
## Software Foundation, Inc., 59 Temple Place, Suite 330, Boston,
## MA 02111-1307 USA

## Commentary:
##    Usaa.pm is a module for geniustrader,
##    http://www.geniustrader.com/.
##   
## Change log:
##

use strict;
use vars qw(@NAMES @ISA);

use GT::Brokers;
use GT::Eval;
use GT::Conf;
use Carp::Datum;

@NAMES = ("Usaa[#1]");
@ISA = qw(GT::Brokers);

=head1 GT::Brokers::Usaa

=head2 Overview

This module will calculate all commissions and charges for the
purchase or sale of stock on an exchange according to Usaa brokerage
charge schedules.

=head2 Calculation

For all orders:

  US$21.95 + $0.02 * ( quantity of shares - 1000 ) + $3.00
  
where US$3.00 is the exchange fee, and the charge of US$0.02 for 
shares in excess of 1000.  There is no annual account charge.

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

Return the calculated broker's commission for the given order.

=cut

sub calculate_order_commission {
    DFEATURE my $f;
    my ($self, $order) = @_;
#    my $forfait = $self->{'args'}[0];
    my $commission = 0;
    my $impot_de_bourse = 3.00;
    my $base_chrg = 21.95;
    my $shr_floor = 1000;
    my $shr_chrg = 0.02;
    
    if ( (defined($order->quantity) && $order->quantity) and
         (defined($order->price) && $order->price) ) {

        my $investment = $order->quantity * $order->price;
        my $quantity = $order->quantity;
	
	if ($quantity > $shr_floor ) {
	    $commission = sprintf("%.2f", ($impot_de_bourse + $base_chrg + $shr_chrg * ($shr_floor - $quantity)));} 
	else {
	    $commission = sprintf("%.2f", ($impot_de_bourse + $base_chrg ));} 
    }
    else { 
	print "price or quantity missing!!\n" ;}
	
	return DVAL $commission if ($commission != 0);;
}

=head2 $broker->calculate_annual_account_charge($portfolio, $year)

Returns the amount of money asked by the broker for the given year
according to the given portfolio, which is $0 in the case of USAA Brokerage.

=cut

sub calculate_annual_account_charge {
    DFEATURE my $f;
    my ($self, $portfolio, $year) = @_;

    return DVAL 0;

}

1;
