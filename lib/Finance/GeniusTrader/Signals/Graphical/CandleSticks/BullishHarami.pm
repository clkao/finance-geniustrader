package Finance::GeniusTrader::Signals::Graphical::CandleSticks::BullishHarami;

# Copyright (C) 2007 M.K.Pai
#
# This program is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Signals;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Indicators::CNDL;

@ISA = qw(Finance::GeniusTrader::Signals);
@NAMES = ("BullishHarami");

=head1 Finance::GeniusTrader::Signals::Graphical::CandleSticks::BullishHarami

=head2 Overview

The Bullish Harami signifies a decrease of momentum. It occurs when a
small bullish (empty) line occurs after a large bearish (filled)
line in such a way that close of the bullish line is above the open
of the bearish line and the open of the bullish line is lower than the
close of the bearish line.

The Bullish Harami is a mirror image of the Bearish Engulfing Line.

=head2 Construction

If yesterday closed higher, a Bullish Harami will form when today's open
is above yesterday's close and today's close is above yesterday's open.

=head2 Representation

          | 
	 ###
         ###    _|_
         ###   |   |
         ###   |___|
         ###     |
         ###
   	  |

        Bullish Harami

=head2 Links

1. More information about the bullish harami on Page 33 of the book
"Candlestick Charting Explained" by Gregory L. Morris. Morris says that
this pattern suggests a trend change.

2. Steve Nison also says that the Harami Patterns suggest a trend
change. This is on page 80 of his book "Japanese Candlesticks Charting
Techniques".

3. http://www.equis.com/Customer/Resources/TAAZ/.

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
    
    $self->{'cndl'} = Finance::GeniusTrader::Indicators::CNDL->new($self->{'args'});

    $self->add_indicator_dependency($self->{'cndl'}, 2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $prices = $calc->prices;
    my $cndl_name = $self->{'cndl'}->get_name(0);
    my $bullish_harami_name = $self->get_name(0);;

    return if ($calc->signals->is_available($self->get_name(0), $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $previous_cndl_code = $calc->indicators->get($cndl_name, $i - 1);
    my $cndl_code = $calc->indicators->get($cndl_name, $i);

    # Previous CandleCode from 0 to 15
    # CandleCode from 80 to 111
    if (($previous_cndl_code >= 0) and ($previous_cndl_code <= 15) and
	($cndl_code >= 80) and ($cndl_code <= 111) and
        ($prices->at($i)->[$OPEN] > $prices->at($i - 1)->[$CLOSE]) and
        ($prices->at($i)->[$CLOSE] < $prices->at($i - 1)->[$OPEN])
       )
    {
	$calc->signals->set($bullish_harami_name, $i, 1);
    } else { 
	$calc->signals->set($bullish_harami_name, $i, 0);
    }
}    

1;
