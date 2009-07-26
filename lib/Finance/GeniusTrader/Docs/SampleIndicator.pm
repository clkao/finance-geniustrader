package Finance::GeniusTrader::Indicators::Example;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Indicators;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("Example[#1]");

=head1 NAME

Finance::GeniusTrader::Indicators::Example - The example indicator

=head1 DESCRIPTION

The Example indicator trys to express X, Y, Z. 

=head2 Calculation

The Example indicator is calculated by ...

=head2 Parameters

=over

=item The number of days of the average ...

=back

=cut

sub initialize {
    my $self = shift;

    # Here you create other indicators that you may need later
    # to do your calculations
    #
    # $self->{'otherindic'} = Finance::GeniusTrader::Indicators::Other->new([ ... ]);
    #
    # And you add the required dependencies
    if ($self->{'args'}->is_constant())
    {
	# Fixed dependencies
	$self->add_prices_dependency($self->{'args'}->get_arg_constant(1))
    } else {
	# no hardcoded dependency
	# they are computed at calculation time
    }
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}[0];
    my $name = $self->get_name;
    my $returnvalue = 0;
    
    return if ($calc->indicators->is_available($name, $i));
    
    if ($i >= $nb - 1) # Check that we can calculate
    {
	# Calculate the indicator
	$returnvalue = 42;

	# Store the value of the indicator
	$calc->indicators->set($name, $i, $returnvalue);
    }
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $nb = $self->{'args'}[0];
    my $name = $self->get_name;
    my $returnvalue = 0;

    # Stop if no calculation needed
    return if ($last <= $calc->indicators->is_available($name));
    
    # Start <nb> days before the first day needed or the first day
    # otherwise
    if ($first >= $nb) {
	$first = $first - $nb + 1;
    } else {
	$first = 0;
    }

    # Calculate the new AMA value from the previous one when possible
    for(my $i = $first; $i <= $last; $i++)
    {
	# Calculate the indicator in a more clever way
	$returnvalue = 42;

	# Store the indicator value
	$calc->indicators->set($name, $i, $returnvalue);
    }
}
