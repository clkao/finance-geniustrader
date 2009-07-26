package GT::Signals::Graphical::CandleSticks::BearishEngulfingLine;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Prices;
use GT::Indicators::CNDL;

@ISA = qw(GT::Signals);
@NAMES = ("BearishEngulfingLine");

=head1 GT::Signals::Graphical::CandleSticks::BearishEngulfingLine

=head2 Overview

The Bearish Engulfing Line is a strongly bearish if it occurs after a significant up-trend (i.e., it acts as a reversal pattern). It occurs when a small bullish (empty) line is engulfed by a large bearish (filled-in) line.

Engulfing Lines are one of the most important and powerful candle patterns. To form the pattern, today's range encloses or "engulfs" the
prior day's range, thereby indicating great market strength in the direction of today's close.

From a psychological perspective, Engulfing Lines indicate that the market opened in the same direction as the prior day, but then reversed sentiment to close strongly in the opposite direction, overcoming and reversing yesterday's assumption regarding value.

=head2 Construction

If yesterday closed lower, a Bullish Engulfing Line will form when today's open is below yesterday's close abd today's close is above yesterday's open. The Bearish Line is just the opposite, where a black body enckises a previous white body.

=head2 Representation

               | 
	      ###
       _|_    ### 
      |   |   ###
      |___|   ###
        |     ###
              ###
   	       |

 Bearish Engulfing Line

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

    $self->add_indicator_dependency($self->{'cndl'}, 2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $prices = $calc->prices;
    my $cndl_name = $self->{'cndl'}->get_name(0);
    my $bearish_engulfing_line_name = $self->get_name(0);;

    return if ($calc->signals->is_available($self->get_name(0), $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $previous_cndl_code = $calc->indicators->get($cndl_name, $i - 1);
    my $cndl_code = $calc->indicators->get($cndl_name, $i);

    # Previous CandleCode from 80 to 111
    # CandleCode from 0 to 15
    if (($previous_cndl_code >= 80) and ($previous_cndl_code <= 111) and
	($cndl_code >= 0) and ($cndl_code <= 15) and
        ($prices->at($i)->[$OPEN] > $prices->at($i - 1)->[$CLOSE]) and
        ($prices->at($i)->[$CLOSE] < $prices->at($i - 1)->[$OPEN])
       )
    {
	$calc->signals->set($bearish_engulfing_line_name, $i, 1);
    } else { 
	$calc->signals->set($bearish_engulfing_line_name, $i, 0);
    }
}    

1;
