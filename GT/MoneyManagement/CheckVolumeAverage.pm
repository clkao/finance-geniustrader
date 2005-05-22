package GT::MoneyManagement::CheckVolumeAverage;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Indicators;
use GT::Indicators::SMA;

@NAMES = ("CheckVolumeAverage[#1,#2]");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::CheckVolumeAverage

=head2 Overview

This money management rule will keep an eye to the size of each trade to
remain them below a fixed percentage of the n-days volume average.

=head2 Parameters

By default, we will accept all trades representing less than 1 % of the 5
days average volume and reject others.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ 5, 0.01 ] };

    $args->[0] = 5 if (! defined($args->[0]));
    $args->[1] = 0.01 if (! defined($args->[1]));
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub initialize {
    my $self = shift;

    $self->{'sma'} = GT::Indicators::SMA->new([ $self->{'args'}[0] ], "Volume Average", $GET_VOLUME);

    $self->add_indicator_dependency($self->{'sma'}, 1);
    $self->add_prices_dependency(1);
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $volume_average = $self->{'sma'};
    my $volume_average_name = $volume_average->get_name;
    my $percentage = $self->{'args'}[1];
    my $indic = $calc->indicators;

    # Return if all required dependencies aren't already calculated
    return if (! $self->check_dependencies($calc, $i));

    # Get N-Days Average Volume value
    my $volume_average_value = $indic->get($volume_average_name, $i);

    # Calculate the required volume to play the trade
    my $required_volume = $volume_average_value * $percentage;

    if (defined($order->{'quantity'})) {
	if ($order->{'quantity'} < $required_volume) {
	    return $order->{'quantity'};
	}
    }
}

1;
