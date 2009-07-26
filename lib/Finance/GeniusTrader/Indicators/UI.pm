package Finance::GeniusTrader::Indicators::UI;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("UI[#*]");
@DEFAULT_ARGS = ("{I:Prices HIGH}", "{I:Prices CLOSE}");

=head1 Finance::GeniusTrader::Indicators::UI

=head2 Overview

The Ulcer Index (UI) is a risk measurement tool superior to the standard deviation because it differentiates between rising returns and losses.
Investors do not view a set of rising returns as a negative sign of volatility, after all; one of the investor goals is to avoid losses.

=head2 Calculation

It is the square root of the average of the squared retracements from the latest high.

=head2 Example

Finance::GeniusTrader::Indicators::UI->new()

=cut

sub initialize {
    my $self = shift;
    $self->add_arg_dependency(1,2);
    $self->add_arg_dependency(2,2);
}

=head2 Finance::GeniusTrader::Indicators::UI::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $q = $calc->prices;
    my $ui_name = $self->get_name(0);
    my $max = 0;
    my $retracement = 0;
    my $squared_retracement = 0;
    my $sum_of_all_squared_retracements = 0;

    return if ($indic->is_available($ui_name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    for (my $n = 0; $n <= $i; $n++) {
        # We need to know what's the previous Highest High
        if ( $self->{'args'}->get_arg_values($calc, $n, 1) > $max ) {
	   $max = $self->{'args'}->get_arg_values($calc, $n, 1);
	}

	if ($max > 0) {
	    $retracement = ($max - $self->{'args'}->get_arg_values($calc, $n, 2)) * 100 / $max;
	    $squared_retracement = $retracement ** 2;
	    $sum_of_all_squared_retracements += $squared_retracement;
	}
    }
    
    my $average_squared_retracements = $sum_of_all_squared_retracements / ($i + 1);
    my $ui_value = sqrt($average_squared_retracements);

    # Return the result
    $indic->set($ui_name, $i, $ui_value);
}

1;
