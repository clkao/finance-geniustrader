package Finance::GeniusTrader::Signals::Swing::Trend;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Signals;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Signals);
@NAMES = ("TrendUp", "TrendDown");

=pod

=head1 Finance::GeniusTrader::Signals::Swing::Trend

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { "args" => [] };
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;

    $self->add_prices_dependency(3);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $q = $calc->prices;
    my $name_up = $self->get_name(0);
    my $name_down = $self->get_name(1);

    return if ($calc->signals->is_available($name_up, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    if ( # New tops each day
	 $q->at($i)->[$HIGH] >= $q->at($i-1)->[$HIGH] &&
	 $q->at($i-1)->[$HIGH] > $q->at($i-2)->[$HIGH] &&
	 # Each bottom is higher
	 $q->at($i)->[$LOW] > $q->at($i-1)->[$LOW] &&
	 $q->at($i-1)->[$LOW] > $q->at($i-2)->[$LOW] &&
	 # The two first candle are white
	 $q->at($i-2)->[$LAST] > $q->at($i-2)->[$FIRST] &&
	 $q->at($i-1)->[$LAST] > $q->at($i-1)->[$FIRST]
       )
    {
	$calc->signals->set($name_up, $i, 1);
    } else {
	$calc->signals->set($name_up, $i, 0);
    }

    if ( # New bottoms each day
         $q->at($i)->[$LOW] <= $q->at($i-1)->[$LOW] &&
         $q->at($i-1)->[$LOW] < $q->at($i-2)->[$LOW] &&
         # Each top is lower
         $q->at($i)->[$HIGH] < $q->at($i-1)->[$HIGH] &&
         $q->at($i-1)->[$HIGH] < $q->at($i-2)->[$HIGH] &&
         # The two first candle are black
         $q->at($i-2)->[$LAST] < $q->at($i-2)->[$FIRST] &&
         $q->at($i-1)->[$LAST] < $q->at($i-1)->[$FIRST]
       )
    {
	$calc->signals->set($name_down, $i, 1);
        return 1;
    } else { 
	$calc->signals->set($name_down, $i, 0);
    }
}    

1;
