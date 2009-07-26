package GT::Signals::Graphical::CandleSticks::GravestoneDoji;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Prices;
use GT::Indicators::CNDL;

@ISA = qw(GT::Signals);
@NAMES = ("GravestoneDoji");

=head1 GT::Signals::Graphical::CandleSticks::GravestoneDoji

=head2 Overview

The Gravestone Doji is a reversal pattern that signifies a turning point. It occurs when the open, close, and low are the same, and the high is significantly higher than the open, low, and closing prices.

=head2 Representation

 |
 |
 |
---

79
 
=head2 Links

http://www.equis.com/free/taaz/candlesticks.html

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [] };
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;
    
    $self->{'cndl'} = GT::Indicators::CNDL->new($self->{'args'});

    $self->add_indicator_dependency($self->{'cndl'}, 1);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $cndl_name = $self->{'cndl'}->get_name(0);
    my $gravestone_doji_name = $self->get_name(0);;

    return if ($calc->signals->is_available($self->get_name(0), $i));
    return if (! $self->check_dependencies($calc, $i));

    my $cndl_code = $calc->indicators->get($cndl_name, $i);

    if ($cndl_code eq 79) {
	$calc->signals->set($gravestone_doji_name, $i, 1);
    } else { 
	$calc->signals->set($gravestone_doji_name, $i, 0);
    }
}    

1;
