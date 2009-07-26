package GT::MoneyManagement::FixedRatio;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Prices;

@NAMES = ("FixedRatio[#1,#2]");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::FixedRatio

=head2 Overview

This money management rule is described in Ryan Jones's book "The Trading
Game" as an alternative to the standard Fixed Fractional type of money
management rules.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;

    # Initialization of $margin and $delta
    my $margin = (defined($self->{'args'}[0])) ? $self->{'args'}[0] : $calc->prices->at($i)->[$LAST];
    my $delta = (defined($self->{'args'}[1])) ? $self->{'args'}[1] : $margin / 100;

    # Initialization of portfolio value
    my $cash = $portfolio->current_cash;
    my $positions = $portfolio->current_evaluation;
    my $upcoming_gains_or_losses = $portfolio->current_marged_gains;
    my $portfolio_value = $cash + $positions + $upcoming_gains_or_losses;

    # Calculate the number of units at which the deltas required and the
    # margin required to increase to one additional contract occurs.
    my $number_of_units = $margin / $delta;

    # Apply the following calculation to determine the starting balance
    my $total_margin_for_units = $number_of_units * $margin;
    my $total_required_to_increase_to_units_using_delta = ($number_of_units * $number_of_units - $number_of_units) / 2 * $delta;
    my $starting_account_balance = $total_margin_for_units - $total_required_to_increase_to_units_using_delta;
    
    # Calculate the number of shares to trade according to the fixed ratio
    my $sum = $starting_account_balance;
    my $number_of_shares = 1;
    
    while ($sum <= $portfolio_value) {
	$sum += ($delta * ($number_of_shares - 1));
	$number_of_shares += 1;
    }
    
    return $number_of_shares;
}

1;
