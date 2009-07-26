package GT::MoneyManagement::ShareMultiples;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Prices;

@NAMES = ("ShareMultiples[#1, #2]");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::ShareMultiples

=head2 Overview

This money management rule will provide you a tool to buy/sell round lots
of shares (ie: multiples of 5, 10 or 50).

=head2 Parameters

By default, the first parameter is initialized to 10 and will provide
share multiples of 10 stocks. The second option is set up to zero and
represent the calculation method, but look at all options :

0 : round to the nearest multiple
1 : round to the lower multiple
2 : round to the upper multiple

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ 10, 0 ] };

    $args->[0] = 10 if (! defined($args->[0]));
    $args->[1] = 0 if (! defined($args->[1]));
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $multiple = $self->{'args'}[0];
    my $calculation_method = $self->{'args'}[1];
 
    if (defined($order->{'quantity'})) {

	my $round_quantity = int($order->{'quantity'} / $multiple) * $multiple;
	my $remains = $order->{'quantity'} - $round_quantity;
	
	if ($calculation_method eq 0) {
	    if ($remains >= ($multiple / 2)) {
		return ($round_quantity + $multiple);
	    } else {
		return $round_quantity;
	    }
	}
	if ($calculation_method eq 1) {
	    return $round_quantity;
	}
	if ($calculation_method eq 2) {
            return ($round_quantity + $multiple);
        }
    }
}

1;
