package GT::Signals::Swing::TrendEnding;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Prices;
use GT::Signals;
use GT::Signals::Swing::Trend;

@ISA = qw(GT::Signals);
@NAMES = ("TrendUpEnding", "TrendDownEnding");

=pod

=head1 GT::Signals::Swing::TrendUpEnding

An up-trend is going on and a little candle is constated. The trend may be
ending ...

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $self = { "args" => [] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my $self = shift;

    $self->{'trend'} = GT::Signals::Swing::Trend->new();

    $self->add_signal_dependency($self->{'trend'}, 2);
    $self->add_prices_dependency(3);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $q = $calc->prices;
    my $sig = $calc->signals;
    my $trend_up_name = $self->{'trend'}->get_name(0);
    my $trend_down_name = $self->{'trend'}->get_name(1);
    
    return if (! $calc->signals->is_available($trend_up_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $max = $q->at($i-2)->[$HIGH] - $q->at($i-2)->[$LOW];
    if ($q->at($i-1)->[$HIGH] - $q->at($i-1)->[$LOW] > $max)
    {
	$max = $q->at($i-1)->[$HIGH] - $q->at($i-1)->[$LOW];
    }

    if ( # Trend up
	 $sig->get($trend_up_name, $i - 1) &&
	 # Last candle less than a third of the biggest candle
	 ($q->at($i)->[$HIGH] - $q->at($i)->[$LOW] < $max / 3)
       )
    {
	$sig->set($self->get_name(0), $i, 1);
    } else {
	$sig->set($self->get_name(0), $i, 0);
    }

    if ( # Trend down
         $sig->get($trend_down_name, $i - 1) &&
         # Last candle less than a third of the biggest candle
         ($q->at($i)->[$HIGH] - $q->at($i)->[$LOW] < $max / 3)
       )
    {   
        $sig->set($self->get_name(1), $i, 1);
        return 1;
    } else {
        $sig->set($self->get_name(1), $i, 0);
    }    
}

1;
