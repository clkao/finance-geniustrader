package Finance::GeniusTrader::MoneyManagement::AntiMartingale;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::MoneyManagement;
use Finance::GeniusTrader::Prices;

@NAMES = ("AntiMartingale");
@ISA = qw(Finance::GeniusTrader::MoneyManagement);

=head1 Finance::GeniusTrader::MoneyManagement::AntiMartingale

=head2 Introduction

Before reading this you should look at the Martingale system. This system
is designed for use on the even chance bets on a roulette table but can be
used on any even chance bets.

=head2 Concept

Playing the Anti-Martingale is precisely what the name suggests, it's the
Martingale in reverse. Instead of doubling your bets after a losing spin
you double your bet after a winning spin. Basically you place a bet on an
even chance and `let it ride' for a set number of spins. Before starting
the system you must decide how many spins you are going to play for,
alternatively you may decide to remove your winnings when your nerve
breaks or even remove part of the winnings after a number of spins and let
the remaining bet continue for a little bit longer.

=head2 Links

http://www.casino-help.com/systems/martingale.shtml
http://roulette.casino.com/article.pl/aid=mathematical_systems_part_1

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
    my $no_bad_long_position = 0;
    my $no_bad_short_position = 0;
    my $bet_size_from_opened_positions = 0;
    my $bet_size = 0;
    my $continue = 1;
    my $init = 0;
 
    if (defined($order->{'quantity'})) {

	# Initialize @closed_positions with the list of history positions
	# already closed and @openning_positions with the list of
	# positions currently opened; calculte their size.
	
	my @closed_positions = $portfolio->list_history_positions($code, $source);
	my @opened_positions = $portfolio->get_position($code, $source);
	my $size_closed_positions = scalar @closed_positions;
	my $size_opened_positions = scalar @opened_positions;
	my $size_real_opened_positions = 0;
	
	for (my $j = 0; $j < $size_opened_positions; $j++) {

	    my $position = $opened_positions[$size_opened_positions - $j - 1];
	    if ($position) {

		$size_real_opened_positions += 1;
		if (($i < ($prices->count() - 1)) and ($continue eq 1)) {
		    if ($position->{'long'} eq 1) {
			if (($prices->at($i+1)->[$OPEN] - $position->{'open_price'}) > 0) {
			
			    # Increase $bet_size because of this loosing long position
			    $bet_size_from_opened_positions += 1;
			    $no_bad_long_position = 0;
			} else {
			    $no_bad_long_position = 1;
			}
		    } else {
			if (($position->{'open_price'} - $prices->at($i+1)->[$OPEN]) > 0) {
			
			    # Increase $bet_size because of this loosing short position
			    $bet_size_from_opened_positions += 1;
			    $no_bad_short_position = 0;
			} else {
			    $no_bad_short_position = 1;
			}
		    }
		    if (($no_bad_long_position eq 1) and ($no_bad_short_position eq 1)) {
			$continue = 0;
		    } else {
			$init = 1 if ($j eq 0);
		    }
		}
	    }
	}

	for (my $j = 0; $j < $size_closed_positions; $j++) {
	   
	    # Increase the bet size according to the number of previous
	    # loosing trades we made.
	    my $position = $closed_positions[$size_closed_positions - $j - 1];
	    if ( ($position->stats->{'sold'} > $position->stats->{'bought'}) and ($continue eq 1) ) {
		$bet_size += 1;
	    } else {
		$continue = 0;
	    }
	}
	
	# Initialize bet_size to zero when the last already opened position is not a loser
	if (($init eq 1) and ($bet_size_from_opened_positions < $size_real_opened_positions)) {
	    $bet_size = 0;
	}

	# Summarize both bet size values and add 1
	$bet_size += $bet_size_from_opened_positions + 1;
	return ($order->{'quantity'} * 2 ** $bet_size);
    }
}

1;
