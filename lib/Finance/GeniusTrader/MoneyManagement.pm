package Finance::GeniusTrader::MoneyManagement;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT %OBJECT_REPOSITORY);

require Exporter;
@ISA = qw(Exporter Finance::GeniusTrader::Dependency);
@EXPORT = qw(&build_object_name &manage_object);

use Finance::GeniusTrader::Registry;
use Finance::GeniusTrader::Dependency;
use Finance::GeniusTrader::Prices;
#ALL#  use Log::Log4perl qw(:easy);

=head1 NAME

Finance::GeniusTrader::MoneyManagement - Money management rules (risk management)

=head1 DESCRIPTION

Money management rules decide or modify the sum of money
placed on each trade. On the extreme side, they can cancel
an order by deciding that 0 shares should be bought/sold.

=over

=item C<< $mm_rule->manage_quantity($order, $i, $calc, $portfolio) >>

Return the quantity that the money management rule would put
on the given order. $order->{'quantity'} may be already set by a
previous money management rule. Never modify the quantity directly
but return the new proposed quantity.

=cut
sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    
    if (defined($order->{'quantity'}) &&
	$order->{'quantity'})
    {
	return $order->{'quantity'};
    } else {
	if (defined($portfolio->{'initial_sum'}))
	{
	    if ($order->{'price'})
	    {
		return int(($portfolio->{'initial_sum'} ) / 
                    $order->{'price'});
	    } else {
		return int(($portfolio->{'initial_sum'} ) / 
                    $calc->prices->at($i)->[$LAST]);
	    }
	}
    }

    return 100;
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
