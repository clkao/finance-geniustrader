package Finance::GeniusTrader::Indicators::REMA;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::SMA;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("REMA[#*]");
@DEFAULT_ARGS = (20, 0.5, "{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::REMA - Regularized Exponential Moving Average

=head1 DESCRIPTION 

Regularized EMA This modification of the classical EMA is described in
Stock&Commodities (July 2003). It is an adaption that includes the
momentum / second derivation of the value into the MA.

It should be used for the calculation of the MACD. The classical EMA
is calculated as:

F(n+1)=F(n)+A*[G(n+1)-F(n)]    ---    A(alpha): A=2/(Period+1) 

The REMA is calculated as followed:

 F(n+1)={F(n)*(1+2*L)+A*[G(n+1)-F(n)]-L*[F(n-1)]}/(1+L)

 with L(Lambda) as Regularization Factor.
 Lambda should be > 0.5


=head2 Parameters

=over 

=item Period (default 20)

The first argument is the period used to calculed the average.

=item Lambda (default 0.5)

See above

=item Other data input

The second argument is optional. It can be used to specify an other
stream of input data for the average instead of the close prices.
This is usually an indicator (detailed via {I:MyIndic <param>}).

=back

=cut

sub initialize {
    my ($self) = @_;
    $self->{'sma'} = Finance::GeniusTrader::Indicators::SMA->new([$self->{'args'}->get_arg_names(1), $self->{'args'}->get_arg_names(3) ]);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $lambda = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $name = $self->get_name;
    
    return if (! defined($nb));
    
    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency($self->{'sma'}, $nb);
    $self->add_volatile_arg_dependency(3, $nb);
    
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $alpha = 2 / ($nb + 1);

    my $ema = $self->{'args'}->get_arg_values($calc, $i - $nb + 1, 3);
    if ($calc->indicators->is_available($name, $i-$nb))
    {
	$ema = $calc->indicators->get($name, $i-$nb);
    } 
    elsif ($i >= 4*$nb - 1)
    {			
		
	my @ema = ();
	for (my $bar = $i - 3*$nb; $bar <= $i-$nb; $bar++)
	{		
	    if (defined ($ema[$bar-$nb]))
	    {
		$ema = $ema[$bar-$nb];
	    }
	    else 
	    {
		# This may look a bit dodgy but if the next line is omitted, SMA.pm uses calculate_interval
		# which fails in this context. Actually, this might be a bug in SMA.pm.
		$self->{'sma'}->calculate($calc, $bar - $nb);
		$ema = $calc->indicators->get($self->{'sma'}->get_name(0), $bar-$nb);
	    }
	    for (my $n = $bar - $nb + 1; $n <= $bar; $n++) 
	    {
		$ema = ( $ema * (1-$alpha) ) + ( $alpha * $self->{'args'}->get_arg_values($calc, $n, 3) );
		$ema = $ema + ( (1+2*$lambda) * $self->{'args'}->get_arg_values($calc, $n, 3) )
		    - ( $lambda * $self->{'args'}->get_arg_values($calc, $n-1, 3) );
		$ema = $ema / (1+$lambda);

	    }
	    $ema[$bar] = $ema;
	}
    }
    elsif ($i >= 2*$nb - 1)
    {				
		
	$self->{'sma'}->calculate($calc, $i - $nb);
	$ema = $calc->indicators->get($self->{'sma'}->get_name(0), $i-$nb);
    }	
	
    return if (! defined($ema));
	
    for (my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	$ema *= (1 - $alpha);
	$ema += ($alpha * $self->{'args'}->get_arg_values($calc, $n, 3));
    }
	
    $calc->indicators->set($name, $i, $ema);
}

1;
