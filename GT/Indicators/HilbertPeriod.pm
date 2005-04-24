package GT::Indicators::HilbertPeriod;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Indicators::WMA;
use GT::Indicators::WTCL;
use GT::Indicators::Generic::ByName;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("HilbertPeriod", "HP:Detrender", "HP:Q1", "HP:I1", "HP:jI", 
	  "HP:jQ", "HP:I2", "HP:Q2", "HP:Re", "HP:Im");

=head1 GT::Indicators::HilbertPeriod

=head2 Overview

=head2 Calculation

=head2 Examples

=head2 Links

TASC November 2000 - page 108

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args) = @_;
    my $self = { 'args' => defined($args) ? $args : [] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my $self = shift;
    
    # Initilize TR (True Range)
    $self->{'median'} = GT::Indicators::WTCL->new([0]);
    $self->{'smoother'} = GT::Indicators::WMA->new([4,
      "{I:Generic:ByName " . $self->{'median'}->get_name . "}" ]);

    $self->add_indicator_dependency($self->{'median'}, 1);
    
}

=head2 GT::Indicators::HilbertPeriod::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $smoother_name = $self->{'smoother'}->get_name;
    
    return if ($indic->is_available($self->get_name, $i));
    
    $self->{'median'}->calculate_interval($calc, 0, $i);
    $self->{'smoother'}->calculate_interval($calc, 0, $i);
    
    for(my $n = 0; $n <= 24; $n++)
    {
	$indic->set($self->get_name, $n, 0);
    }
    for(my $n = 0; $n <= $i; $n++)
    {
	# Calcul de detrender
	if ($indic->is_available_interval($smoother_name, $n - 6, $n) &&
	    $indic->is_available($self->get_name, $n - 1))
	{
	    $indic->set("HP:Detrender", $n,
		(
		0.25 * $indic->get($smoother_name, $n) +
		0.75 * $indic->get($smoother_name, $n - 2) -
		0.75 * $indic->get($smoother_name, $n - 4) -
		0.25 * $indic->get($smoother_name, $n - 6) 
		) * (0.046 * $indic->get($self->get_name, $n - 1) + 0.332)
	    );
	}

	# Calcul de Q1
	if ($indic->is_available_interval("HP:Detrender", $n - 6, $n) &&
	    $indic->is_available($self->get_name, $n - 1))
	{
	    $indic->set("HP:Q1", $n,
		(
		0.25 * $indic->get("HP:Detrender", $n) +
		0.75 * $indic->get("HP:Detrender", $n - 2) -
		0.75 * $indic->get("HP:Detrender", $n - 4) -
		0.25 * $indic->get("HP:Detrender", $n - 6) 
		) * (0.046 * $indic->get($self->get_name, $n - 1) + 0.332)
	    );
	}
	
	# Calcul de I1
	if ($indic->is_available("HP:Detrender", $n - 3))
	{
	    $indic->set("HP:I1", $n, 
		$indic->get("HP:Detrender", $n - 3)
	    );
	}
	
	# Calcul de jI
	if ($indic->is_available_interval("HP:I1", $n - 6, $n))
	{
	    $indic->set("HP:jI", $n,
		0.25 * $indic->get("HP:I1", $n) +
		0.75 * $indic->get("HP:I1", $n - 2) -
		0.75 * $indic->get("HP:I1", $n - 4) -
		0.25 * $indic->get("HP:I1", $n - 6) 
	    );
	}

	# Calcul de jQ
	if ($indic->is_available_interval("HP:Q1", $n - 6, $n))
	{
	    $indic->set("HP:jQ", $n,
		0.25 * $indic->get("HP:Q1", $n) +
		0.75 * $indic->get("HP:Q1", $n - 2) -
		0.75 * $indic->get("HP:Q1", $n - 4) -
		0.25 * $indic->get("HP:Q1", $n - 6) 
	    );
	}

	# Calcul de I2
	if ($indic->is_available("HP:I1", $n) &&
	    $indic->is_available("HP:jQ", $n))
	{
	    $indic->set("HP:I2", $n, 
		$indic->get("HP:I1", $n) - $indic->get("HP:jQ", $n)
	    );
	}
	
	# Calcul de Q2
	if ($indic->is_available("HP:Q1", $n) &&
	    $indic->is_available("HP:jI", $n))
	{
	    $indic->set("HP:Q2", $n, 
		$indic->get("HP:Q1", $n) + $indic->get("HP:jI", $n)
	    );
	}

	# Calcul de I2 bis
	if ($indic->is_available_interval("HP:I2", $n - 1, $n))
	{
	    $indic->set("HP:I2", $n,
		0.15 * $indic->get("HP:I2", $n) +
		0.85 * $indic->get("HP:I2", $n - 1)
	    );
	}

	# Calcul de Q2 bis
	if ($indic->is_available_interval("HP:Q2", $n - 1, $n))
	{
	    $indic->set("HP:Q2", $n,
		0.15 * $indic->get("HP:Q2", $n) +
		0.85 * $indic->get("HP:Q2", $n - 1)
	    );
	}

	# Calcul de Re et Im
	if ($indic->is_available_interval("HP:I2", $n - 1, $n) &&
	    $indic->is_available_interval("HP:Q2", $n - 1, $n))
	{
	    my $X1 = $indic->get("HP:I2", $n) * $indic->get("HP:I2", $n - 1);
	    my $X2 = $indic->get("HP:I2", $n) * $indic->get("HP:Q2", $n - 1);
	    my $Y1 = $indic->get("HP:Q2", $n) * $indic->get("HP:Q2", $n - 1);
	    my $Y2 = $indic->get("HP:Q2", $n) * $indic->get("HP:I2", $n - 1);
	    $indic->set("HP:Re", $n, $X1 + $Y1);
	    $indic->set("HP:Im", $n, $X2 - $Y2);
	}
	
	# Calcul de Re bis
	if ($indic->is_available_interval("HP:Re", $n - 1, $n))
	{
	    $indic->set("HP:Re", $n,
		0.2 * $indic->get("HP:Re", $n) +
		0.8 * $indic->get("HP:Re", $n - 1)
	    );
	}

	# Calcul de Im bis
	if ($indic->is_available_interval("HP:Im", $n - 1, $n))
	{
	    $indic->set("HP:Im", $n,
		0.2 * $indic->get("HP:Im", $n) +
		0.8 * $indic->get("HP:Im", $n - 1)
	    );
	}

	# Calcul de HilbertPeriod
	if ($indic->is_available("HP:Im", $n) &&
	    $indic->is_available("HP:Re", $n) &&
	    $indic->is_available("HilbertPeriod", $n - 1))
	{
	    my $im = $indic->get("HP:Im", $n);
	    my $re = $indic->get("HP:Re", $n);
	    my $prev_period = $indic->get("HilbertPeriod", $n - 1);
	    my $period = 0;

	    if (($re != 0) and ($im != 0))
	    {
		$period = 1 / (POSIX::atan($im / $re) / (2 * 3.1415));
	    }

	    if ($period > 1.5 * $prev_period)
	    {
		$period = 1.5 * $prev_period;
	    }

	    if ($period < 0.67 * $prev_period)
	    {
		$period = 0.67 * $prev_period;
	    }

	    $period = 6 if ($period < 6);
	    $period = 50 if ($period > 50);
	    
	    $period = 0.2 * $period + 0.8 * $prev_period;
	    
	    $indic->set("HilbertPeriod", $n, $period);
	}
    }	    
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    # Calculate ADX for the last record
    # so that all intermediate values will be stored
    $self->calculate($calc, $last);

}

1;
