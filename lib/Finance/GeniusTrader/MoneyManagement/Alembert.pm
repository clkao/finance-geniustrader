package Finance::GeniusTrader::MoneyManagement::Alembert;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::MoneyManagement;
use Finance::GeniusTrader::Prices;

@NAMES = ("Alembert");
@ISA = qw(Finance::GeniusTrader::MoneyManagement);

=head1 Finance::GeniusTrader::MoneyManagement::Alembert

=head2 Introduction

The d'Alembert System is a progression system which tries to win back your
losses in small steps instead of all at once like the Martingale. It was
designed for use on the even chance bets on a roulette table but can be
used on any even chance bet.

=head2 Concept

The d'Alembert System works under the assumption that over a period of
time there will be an equal number of `reds' and `blacks'. We start the
session by placing one unit ($1, $5 or any other value) on one of the even
chance bets (e.g. `red'), after a losing spin we increase the next bet by
one unit and after a winning bet we decrease the next bet by one unit. So
if we were betting oin `red' and the spins were - black, black, black,
red, black, red, red, black, red, red, red - then the bets placed would be
as follows (the numbers in brackets show the level of your bankroll after
the spin):

1 (-1), 2 (-3), 3 (-6), 4 (-2), 3 (-5), 4 (-1), 3 (+2), 2 (+0), 3 (+3), 2
(+5), 1 (+6)

This sequence would end with a win of $6. As you can see, as soon as the
number of `reds' is equal to the number of `blacks' plus one then the
sequence ends with a win. You may also notice that after the 7th, 9th and
10th spins we were also showing a profit, this is because the bets placed
on winning spins are one unit greater than the previous losing spin.
Having the possibility of a positive bankroll before the sequence is
complete allows us to choose to cut the session short and take a smaller
win rather than risking the chance of the session ending badly.

=head2 Links

http://www.casino-help.com/systems/dalembert.shtml

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ ] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}

sub manage_quantity {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    my $prices = $calc->prices;
    my $code = $order->code;
    my $source = $order->source;
    my $bet_size = 1;
 
    if (defined($order->{'quantity'})) {

	# Initialize @closed_positions with the list of history positions
	# already closed and @openning_positions with the list of
	# positions currently opened; calculte their size.
	
	my @closed_positions = $portfolio->list_history_positions($code, $source);
	my @opened_positions = $portfolio->get_position($code, $source);
	my $size_closed_positions = scalar @closed_positions;
	my $size_opened_positions = scalar @opened_positions;
	
	for (my $j = 0; $j < $size_opened_positions; $j++) {

	    my $position = $opened_positions[$size_opened_positions - $j - 1];
	    if ($position) {

		if ($i < ($prices->count() - 1)) {
		    if ($position->{'long'} eq 1) {
			if (($prices->at($i+1)->[$OPEN] - $position->{'open_price'}) < 0) {
			
			    # Increase bet_size after this loosing long position
			    $bet_size += 1;
			} else {

			    # Decrease bet_size after this winning long position
			    $bet_size -= 1;
			}
		    } else {
			if (($position->{'open_price'} - $prices->at($i+1)->[$OPEN]) < 0) {
			
			    # Increase bet_size after this loosing short position
			    $bet_size += 1;
			} else {

			    # Decrease bet_size after this winning short position
			    $bet_size -= 1;
			}
		    }
		}
	    }
	}

	for (my $j = 0; $j < $size_closed_positions; $j++) {
	   
	    # Increase bet size after each loosing position and decrease
	    # it after each winning position.
	    my $position = $closed_positions[$size_closed_positions - $j - 1];
	    if ($position->stats->{'sold'} <= $position->stats->{'bought'}) {
		$bet_size += 1;
	    }
	    if ($position->stats->{'sold'} > $position->stats->{'bought'}) {
                $bet_size -= 1;
            }
	}
	
	# Check that bet_size remains alway above one
	if ($bet_size < 1) {
	    $bet_size = 1;
	}

	return ($order->{'quantity'} * $bet_size);
    }
}

1;
