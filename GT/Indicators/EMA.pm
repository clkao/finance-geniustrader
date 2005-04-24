package GT::Indicators::EMA;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::SMA;

@ISA = qw(GT::Indicators);
@NAMES = ("EMA[#*]");
@DEFAULT_ARGS = (20, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::EMA - Exponential Moving Average

=head1 DESCRIPTION 

An exponential moving average gives more importance to
recent prices ...

=head2 Parameters

=over 

=item Period (default 20)

The first argument is the period used to calculed the average.

=item Other data input

The second argument is optional. It can be used to specify an other
stream of input data for the average instead of the close prices.
This is usually an indicator (detailed via {I:MyIndic <param>}).

=back

=head2 Creation

 GT::Indicators::EMA->new()
 GT::Indicators::EMA->new([20])

If you need a 30 days EMA of the opening prices you can write
one of those lines :

 GT::Indicators::EMA->new([30, "{I:Prices OPEN}"])

A 10 days EMA of the RSI could be created with :

 GT::Indicators::EMA->new([10, "{I:RSI}"])

Z<>

=cut
sub initialize {
    my ($self) = @_;

    $self->{'sma'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names() ]);
    $self->add_indicator_dependency($self->{'sma'}, $self->{'args'}->get_arg_constant(1));
    $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;
    my $days_required = 0;
    if (! $self->{'args'}->is_constant(2)) {
	$days_required = $self->{'args'}->get_arg_object(2)->days_required;
    }
    my $d2 = $self->{'sma'}->days_required + $nb;
    $days_required = ($days_required > $d2) ? $days_required : $d2;
    
    return if (! defined($nb));
    
    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $nb);
    
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $alpha = 2 / ($nb + 1);
	
    my $ema = $self->{'args'}->get_arg_values($calc, $i - $nb + 1, 2);
    
    if ($calc->indicators->is_available($name, $i-$nb))
    {
	$ema = $calc->indicators->get($name, $i-$nb);
    } elsif ($i - $days_required >= 4*$nb - 1)
    {			
	my @ema = ();
	for (my $bar = $i - 3*$nb; $bar <= $i-$nb; $bar++)
	{		
	    if (defined ($ema[$bar-$nb]))
	    {
		$ema = $ema[$bar-$nb];
	    } else 
	    {
		# This may look a bit dodgy but if the next line is omitted, SMA.pm uses calculate_interval
		# which fails in this context. Actually, this might be a bug in SMA.pm.
		$self->{'sma'}->calculate($calc, $bar - $nb);
		$ema = $calc->indicators->get($self->{'sma'}->get_name(0), $bar-$nb);
	    }
	    for(my $n = $bar - $nb + 1; $n <= $bar; $n++) 
	    {
		$ema *= (1 - $alpha);
		$ema += ($alpha * $self->{'args'}->get_arg_values($calc, $n, 2));
	    }
	    $ema[$bar] = $ema;
	}
    } elsif ($i - $days_required >= 2*$nb - 1)
    {				
	$self->{'sma'}->calculate($calc, $i - $nb);
	$ema = $calc->indicators->get($self->{'sma'}->get_name(0), $i-$nb);
    }	
	
    return if (! defined($ema));
	
    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
       $ema *= (1 - $alpha);
       $ema += ($alpha * $self->{'args'}->get_arg_values($calc, $n, 2));
    }
	
    $calc->indicators->set($name, $i, $ema);
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $name = $self->get_name;
    
    #If the EMA period is not a constant value,
    #use the default non-optimized calculate_interval
    if (!$self->{'args'}->is_constant(1)) {
      ($first, $last) = $self->update_interval($calc, $first, $last);
      return if ($calc->indicators->is_available_interval($name, $first, $last));
      return if (! $self->check_dependencies_interval($calc, $first, $last));
      GT::Indicators::calculate_interval(@_);
      return;
    }

    my $nb = $self->{'args'}->get_arg_constant(1);  #Period of the EMA

    my $smooth_constant = 2 / (1 + $nb);   #Applies appropriate weighting to
                                           #the most recent price relative to
                                           #the previous EMA

    my $smooth_periods = -2 / log(1 - $smooth_constant); #The larger this value,
                                   #the more accurate and slower the calculation
                                   #If you calculate for a large interval
                                   #this is only relevant for the first few
                                   #periods. It should always be a multiple
                                    #of $nb.

    $first-=$smooth_periods;      #If we don't do this, the first calculated
                                  #value will be a SMA

    ($first, $last) = $self->update_interval($calc, $first, $last); #Do we need this ?
    return if ($calc->indicators->is_available_interval($name, $first - $nb, $last));
    return if (! $self->check_dependencies_interval($calc, $first - $nb, $last));

    my $sum = 0;
    #Calculate the SMA for the first day
    for(my $i = $first - $nb + 1; $i <= $first; $i++) {
        my $quote = $self->{'args'}->get_arg_values($calc, $i, 2);
        $sum+=$quote;
	}

    #Based on the first smooth period SMA, calculate
    #the following smooth periods EMA
    my $previous_ema = ($sum/$nb);
    for(my $i = $first + 1; $i <= $first + $smooth_periods; $i++)
    {
        my $quote = $self->{'args'}->get_arg_values($calc, $i, 2);
        next if (! defined($quote));

        my $ema_value = ($smooth_constant * ($quote - $previous_ema)) + $previous_ema;
        $previous_ema = $ema_value;
	}

    #Set the EMA for the first value in the requested interval
    $calc->indicators->set($name, $first + $smooth_periods, $previous_ema);

    #Calculate and set the EMA for the following interval periods
    for(my $i = $first + $smooth_periods; $i <= $last; $i++)
    {
        my $quote = $self->{'args'}->get_arg_values($calc, $i, 2);
        next if (! defined($quote));

        my $ema_value = ($smooth_constant * ($quote - $previous_ema)) + $previous_ema;
        $calc->indicators->set($name, $i, $ema_value);
        $previous_ema = $ema_value;
    }
}
