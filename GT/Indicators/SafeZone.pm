package GT::Indicators::SafeZone;

# Copyright 2000-2003 Raphaël Hertzog, Fabien Fulhaber, Oliver Bossert, Joerg Sauer
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::Generic::MaxInPeriod;
use GT::Indicators::Generic::MinInPeriod;
use GT::Tools qw(:math);
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("SafeUp[#*]","SafeDn[#*]");
@DEFAULT_ARGS = (20, 2, 6);

=pod

=head2 GT::Indicators::SafeZone

The SafeZone stop is described in Dr. Alexander Elder's Book "Come into my Trading Room" and provides
stops for closing long or short positions.

It accepts the number of bars to use for the calculation and a coefficient as parameters with 20 and 2 being the defaults that
are also used in the examples in the book. The last parameter is the number of days a "plateau" is maintained regardless of
of prices moving against the trade. This is to take into account the fact that stops may only be extended in the direction of the trade.
After prices have been moving against the trade for the number of bars that is specified by the third parameter it is assumed that the stop 
was triggered and normal calculation of new stops is resumed.

If this doesn't seem to make sense just plot this indicator and you will know what I am trying to say. :)

=cut

sub initialize {
    my $self = shift;

    $self->{'min'} = GT::Indicators::Generic::MinInPeriod->new([ $self->{'args'}->get_arg_constant(3), 
								 "{I:Prices HIGH}" ]);
    $self->{'max'} = GT::Indicators::Generic::MaxInPeriod->new([ $self->{'args'}->get_arg_constant(3), 
								 "{I:Prices LOW}" ]);
						
    $self->add_indicator_dependency($self->{'min'}, 1);
    $self->add_indicator_dependency($self->{'max'}, 1);						
    $self->add_prices_dependency($self->{'args'}->get_arg_constant(1) + $self->{'args'}->get_arg_constant(3));
}

=head2 GT::Indicators::SafeZone::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $coeff = $self->{'args'}->get_arg_values($calc, $i, 2);		
    my $stickiness = $self->{'args'}->get_arg_values($calc, $i, 3);
    my $safeup_name = $self->get_name(0);
    my $safedn_name = $self->get_name(1);
    my $min = $self->{'min'};
    my $max = $self->{'max'};
    my $last_sticky_high = 0;
    my $last_sticky_low = 0;    

    return if ($indic->is_available($safeup_name, $i) &&
	       $indic->is_available($safedn_name, $i));
    return if (! $self->check_dependencies($calc, $i));
	
    my @pen_up = ();
    my @pen_dn = ();
    my $sum_up = 0;
    my $sum_dn = 0;
	
    my $min_value = $indic->get($min->get_name, $i-1);
    my $max_value = $indic->get($max->get_name, $i-1);	
    
    for (my $n = $i - $stickiness; $n < $i; $n++) {
	if ($calc->prices->at($n)->[$LOW] eq $max_value) {
	    $last_sticky_high = $n;
	}	
	if ($calc->prices->at($n)->[$HIGH] eq $min_value) {
	    $last_sticky_low = $n;
	}	
    }	
	
    for (my $n = $last_sticky_high - $period + 1; $n <= $last_sticky_high; $n++) {		
	if ($calc->prices->at($n)->[$LOW] < $calc->prices->at($n-1)->[$LOW]) {
	    push @pen_up, $calc->prices->at($n-1)->[$LOW] - $calc->prices->at($n)->[$LOW];			
	}
    }
    for (my $n = $last_sticky_low - $period + 1; $n <= $last_sticky_low; $n++) {
	if ($calc->prices->at($n)->[$HIGH] > $calc->prices->at($n-1)->[$HIGH]) {
	    push @pen_dn, $calc->prices->at($n)->[$HIGH] - $calc->prices->at($n-1)->[$HIGH];
	}
    }
	
    $sum_up += $_ foreach @pen_up;
    $sum_dn += $_ foreach @pen_dn;
	
    my $avg_up = @pen_up >= 1 ? $sum_up / @pen_up : $sum_up;		
    my $avg_dn = @pen_dn >= 1 ? $sum_dn / @pen_dn : $sum_dn;	
	
    my @safe_up = ();
    my @safe_dn = ();
	
    for (my $n = $i - $stickiness; $n < $i; $n++) {		
	push @safe_up, $calc->prices->at($n)->[$LOW] - $avg_up * $coeff;
	push @safe_dn, $calc->prices->at($n)->[$HIGH] + $avg_dn * $coeff;
    }		
	
    my $safeup_value = max (@safe_up);
    my $safedn_value = min (@safe_dn);	
    
    $indic->set($safeup_name, $i, $safeup_value);
    $indic->set($safedn_name, $i, $safedn_value);
	
}

1;

