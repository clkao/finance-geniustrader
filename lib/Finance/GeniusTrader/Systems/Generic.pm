package Finance::GeniusTrader::Systems::Generic;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Systems;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::Tools qw(:generic);

@ISA = qw(Finance::GeniusTrader::Systems);
@NAMES = ("Generic[#*]");

=head1 Generic System module

 a system runs on two signals: long and short

 these terms imply buying shares when the long signal is triggered
 and selling shares short when the short signal is triggered. in
 either case a new position is thus opened (or maybe added to)
 for the security that caused the signal.

 a generic system description requires two signals, the first
 must define the long signal, the second defines the short signal.

 out on a limb here -- a system description can specify only
 one long and one short signal

 nb: the short signal will not necessarily close a position
 opened by a prior long signal. open position management is
 controlled by a close strategy.

 according to Finance::GeniusTrader::Systems a signal is acted upon in the following
 day (timeframe). if a position is opened (long or short) closing
 that position is controlled by a close strategy (CS). therefore,
 most system descriptions will also include a close strategy
 description.
 
 system description can specify multiple close strategies

 system description can specify multiple money management (MM)
 strategies

 how does OrderFactory (OF) fit in with system description?
 

=head1 Generic System Examples

 SY:Generic \
  {S:Generic:CrossOverUp   {I:SMA 20 {I:Prices CLOSE}} {I:SMA 60 {I:Prices CLOSE}}} \
  {S:Generic:CrossOverDown {I:SMA 20 {I:Prices CLOSE}} {I:SMA 60 {I:Prices CLOSE}}} \
 | TF:OneTrade \
 | CS:OppositeSignal

 the CrossOverUp signal denotes the buy condition
 the CrossOverDown signal denotes the sell condition
 
 notice that the close strategy explicitly specifies that the short
 signal is also used to close open positions, and conversely
 short positions are closed with the long signal.

 the trade filter (TF) (see perldoc ../GT/TradeFilters.pm) will limit
 the number of open positions (either long or short) to one, however
 it will allow a new open position and a closed postion in the same timeframe.
 
 system descriptions can specify multiple trade filters


 SY:Generic inherits new from Finance::GeniusTrader::Systems::

=cut


sub initialize {
    my ($self) = @_;
}

sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;
}

sub long_signal {
    my ($self, $calc, $i) = @_;
    
    return 0 if (! $self->check_dependencies($calc, $i));
    
    if ( $self->{'args'}->get_arg_values($calc, $i, 1) == 1 )
    {
	return 1;
    }
    return 0;
}

sub short_signal {
    my ($self, $calc, $i) = @_;
    
    return 0 if (! $self->check_dependencies($calc, $i));

    if ( $self->{'args'}->get_nb_args() >= 2 && 
	 $self->{'args'}->get_arg_values($calc, $i, 2) == 1 )
    {
	return 1;
    }
    return 0;
}

1;
