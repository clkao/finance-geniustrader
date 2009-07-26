package Finance::GeniusTrader::Indicators::DMI;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::TR;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("UDMI[#1]", "LDMI[#1]", "UDMI-LDMI[#1]");
@DEFAULT_ARGS = (14);

=head1 NAME

Finance::GeniusTrader::Indicators::DMI - 

=head1 DESCRIPTION

=head1 EXAMPLES

=cut

sub initialize {
    my $self = shift;

    $self->{'tr'} = Finance::GeniusTrader::Indicators::TR->new();

    $self->add_indicator_dependency($self->{'tr'}, $self->{'args'}->get_arg_constant(1));
    $self->add_prices_dependency($self->{'args'}->get_arg_constant(1) + 1);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name_u = $self->get_name(0);
    my $name_l = $self->get_name(1);
    my $name_ecart = $self->get_name(2);
    my $prices = $calc->prices;

    return if ($indic->is_available($name_u, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # Calculate the UDMI/LDMI

    my $sum_tr = 0;
    my ($pdm, $mdm, $sum_pdm, $sum_mdm) = (0, 0, 0, 0);
    for(my $n = $i - $self->{'args'}->get_arg_constant(1) + 1; $n <= $i; $n++)
    {
	$sum_tr += $indic->get($self->{'tr'}->get_name, $n);

	if (($prices->at($n)->[$HIGH] < $prices->at($n - 1)->[$HIGH]) &&
	    ($prices->at($n)->[$LOW] > $prices->at($n - 1)->[$LOW]))
	{
	    # UDM/MDM are null if inside day ...
	    next;
	}
	$pdm = $prices->at($n)->[$HIGH] - $prices->at($n - 1)->[$HIGH];
	$mdm = $prices->at($n - 1)->[$LOW] - $prices->at($n)->[$LOW];
	$mdm = ($pdm > $mdm) ? 0 : $mdm;
	$pdm = ($pdm < $mdm) ? 0 : $pdm;

	$sum_pdm += $pdm;
	$sum_mdm += $mdm;
    }
    
    # Return the result
    $indic->set($name_u, $i, 100 * $sum_pdm / $sum_tr);
    $indic->set($name_l, $i, 100 * $sum_mdm / $sum_tr);
    $indic->set($name_ecart, $i, (100 * $sum_pdm / $sum_tr) - 
				 (100 * $sum_mdm / $sum_tr));
}

1;
