package Finance::GeniusTrader::Portfolio;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

#ALL#  use Log::Log4perl qw(:easy);
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::SystemManager;

use Finance::GeniusTrader::Portfolio::Order;
use Finance::GeniusTrader::Portfolio::Position;

use Finance::GeniusTrader::Serializable;

@ISA = qw(Finance::GeniusTrader::Serializable);

=head1 NAME

Finance::GeniusTrader::Portfolio - A portfolio

=head1 DESCRIPTION

A Portfolio is used to keep track of orders. It can calculate a
performance and give useful statistics about what you've done
(average trade gain/loss, percentage of winning/losing trades,
 max draw down, ...).

=over

=item C<< my $p = Finance::GeniusTrader::Portfolio->new; >>

Create a portfolio object without any open positions and without any
pendings orders (ie an empty portfolio).

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { "pending_orders" => [],
		 "open_positions"  => [],  # pointer to positions{uniqid}
		 "history" => [],	   # pointer to positions{uniqid}
		 "positions" => {},        # all positions
		 "discarded_orders" => [], # discarded pending orders
		 "order_id" => 0,
		 "global_position_id" => 0, # for all positions
		 "cash" => 0,
		 "position_evaluation" => {},
		 "position_marged_gains" => {},
		 "evaluation_history" => {}
	       };
    bless $self, $class;
    return $self;
}

=item C<< $p->add_order($order) >>

Add $order to the list of pending orders.

=cut
sub add_order {
    my ($self, $order) = @_;

    #WAR#  WARN  "valid type for order" if ( ref($order) =~ /Portfolio::Order/);
    #WAR#  WARN  "order quantity is positive" if ( $order->quantity > 0);
    
    $order->set_id($self->{'order_id'});
    
    $self->{'order_id'}++;
    $self->{'pending_orders'}[$order->id] = $order;
    return $order->id;
}

=item C<< $p->discard_order($order) >>

Discard the order. Usually that means that it hasn't been executed or
that it has been cancelled.

=cut
sub discard_order {
    my ($self, $order) = @_;

    #WAR#  WARN  "valid type for order" if ( ref($order) =~ /Portfolio::Order/);
    #WAR#  WARN  "order id is positive" if ( $order->id >= 0);
    
    push @{$self->{'discarded_orders'}},
	 $self->{'pending_orders'}[$order->id];
    $self->{'pending_orders'}[$order->id] = undef;
    
    return;
}

sub delete_order {
    my ($self, $order) = @_;

    #WAR#  WARN  "valid type for order" if ( ref($order) =~ /Portfolio::Order/);
    #WAR#  WARN  "order id is positive" if ( $order->id >= 0);
    
    $self->{'pending_orders'}[$order->id] = undef;
    return;
}

=item C<< $p->new_position($code, $source, $date) >>

Create a new open position in the portfolio.

=cut
sub new_position {
    my ($self, $code, $source, $date) = @_;

    my $position = Finance::GeniusTrader::Portfolio::Position->new($code, $source, $date);
    $position->set_id($self->{'global_position_id'}++);
    push @{$self->{'open_positions'}}, $position;
    #DEB#  DEBUG  "position " . $position->id . " opened";

    return $position;
}

=item C<< $p->apply_order_on_position($position, $order, $price, $date) >>

Add the given order to the position and modify the money available in the
portfolio accordingly.

=cut
sub apply_order_on_position {
    my ($self, $position, $order, $price, $date) = @_;
    
    #WAR#  WARN  "valid type for position" if ( ref($position) =~ /Finance::GeniusTrader::Portfolio::Position/);
    #WAR#  WARN  "valid type for order" if ( ref($order) =~ /Finance::GeniusTrader::Portfolio::Order/);
    
    my $stats_before = $position->stats($self);
    $position->apply_order($order, $price, $date);
    my $stats_after = $position->stats($self);
    
    # Update the cash
    if (! $position->is_marged)
    {
	$self->{'cash'} += $stats_after->{'sold'} - $stats_before->{'sold'};
	$self->{'cash'} -= $stats_after->{'bought'} -
			   $stats_before->{'bought'};
    } 
    $self->{'cash'} -= $stats_after->{'cost'} - $stats_before->{'cost'};
    
    if (! $position->is_open)
    {
	$position->set_close_date($date);
	$self->close_position($position);
    }
}

=item C<< $p->close_position($pos) >>

Move the position from the list of open positions to the historic list.
Update the cash with the marged gain.

=cut
sub close_position {
    my ($self, $position) = @_;
    
    #WAR#  WARN  "valid type for position" if ( ref($position) =~ /Finance::GeniusTrader::Portfolio::Position/);
    
    push @{$self->{'history'}}, $position;
    
    # Closed position has no evaluation any more
    delete $self->{'position_evaluation'}{$position->id};

    # Add the gains/losses if the position is marged
    my $stats = $position->stats($self);
    if ($position->is_marged)
    {
	$self->{'cash'} += $stats->{'sold'} - 
			   $stats->{'bought'};
	# Closed positions has no marged gains anymore
	delete $self->{'position_marged_gains'}{$position->id};
    }
    
    # Complicated way of removing a position from the list
    # of open positions
    my $index = -1;
    foreach (@{$self->{'open_positions'}})
    {
	$index++;
	next if (! defined($_));
	if ($_->id eq $position->id)
	{
	    last;
	}
    }
    $self->{'open_positions'}[$index] = undef if ($index != -1);
    #DEB#  DEBUG  "position " . $position->id . " closed";

}

=item C<< $p->apply_pending_orders($calc, $i, $source, $pf_manager, [ $cb ]) >>

Check the pending order for the value indicated by $calc, try to execute
them on the day $i. It restricts itself to the orders coming from
the indicated source. You can pass an optionnal callback for managing
specially the position_opened callback. Not giving this arg and leaving
to its default value is usually ok.

=cut
sub apply_pending_orders {
    my ($self, $calc, $i, $source, $pf_manager, $cb) = @_;

    if (! defined($cb))
    {
	$cb = sub { 
	  my ($calc, $i, $position) = @_;
	  my $sm;
	  $sm = Finance::GeniusTrader::SystemManager::get_registered_object($position->{'source'});
	  $sm->position_opened($calc, $i, $position, $pf_manager) 
							if (defined($sm));
        };
    }

    foreach (@{$self->{'pending_orders'}}) {
	next if (! defined($_));
	next if ($_->code ne $calc->code);
	next if ($_->source ne $source);

	my $price = $_->is_executed($calc, $i);

	if ($price) {
	    # New position !
	    my $position = $self->new_position($calc->code, $source,
				  	    $calc->prices->at($i)->[$DATE]);
	    $position->set_timeframe($calc->current_timeframe);
	    $position->set_marged if ($_->is_marged);
	    
	    $self->apply_order_on_position($position, $_, $price, $calc->prices->at($i)->[$DATE]);
	    
	    $self->update_position_evaluation($position, $calc, $i);
	    
	    # Call the position_opened callback
	    if (defined($cb))
	    {
		&$cb($calc, $i, $position);
	    }
	    $self->delete_order($_);
	} else {
	    if ($_->discardable)
	    {
		$self->discard_order($_);
	    } else {
		# Not discarded
	    }
	}
    }
    return;
}

=item C<< $p->apply_pending_orders_on_position($position, $calc, $i) >>

Apply all pending orders on the position, this does include
the stop.

=cut
sub apply_pending_orders_on_position {
    my ($self, $position, $calc, $i) = @_;

    return if ($position->code() ne $calc->code());

    my $stats_before = $position->stats($self);
    $position->apply_pending_orders($calc, $i);
    my $stats_after = $position->stats($self);

    # Update the cash
    if (! $position->is_marged)
    {
	$self->{'cash'} += $stats_after->{'sold'} - $stats_before->{'sold'};
	$self->{'cash'} -= $stats_after->{'bought'} -
			   $stats_before->{'bought'};
    } 
    $self->{'cash'} -= $stats_after->{'cost'} - $stats_before->{'cost'};

    $self->update_position_evaluation($position, $calc, $i);
    
    if (! $position->is_open)
    {
	$position->set_close_date($calc->prices->at($i)->[$DATE]);
	$self->close_position($position);
    }
}

=item C<< $p->update_position_evaluation($position, $calc, $i) >>

Update the evaluation of the position with data of day $i.

=cut
sub update_position_evaluation {
    my ($self, $position, $calc, $i) = @_;
    my $eval = 0;
    if ($position->is_marged)
    {
	my $s = $position->stats($self);
	if ($position->is_short)
	{
	    $eval = $s->{'sold'} - $s->{'bought'} - 
		 $calc->prices->at($i)->[$LAST] * $position->quantity;
	} else {
	    $eval = $calc->prices->at($i)->[$LAST] * $position->quantity
		+ $s->{'sold'} - $s->{'bought'};
	}
	$self->{'position_marged_gains'}{$position->id} = $eval;
    }
    $eval = $position->quantity * $calc->prices->at($i)->[$LAST];
    $self->{'position_evaluation'}{$position->id} = $eval;
    return;
}

=item C<< $p->store_evaluation($date) >>

Store the cash level and the evaluation of the portfolio for the indicated
date.

=cut
sub store_evaluation {
    my ($self, $date) = @_;
    $self->{'evaluation_history'}{$date} = [ $self->current_cash,
					     $self->current_evaluation,
					     $self->current_marged_gains,
					     $self->current_marged_investment ];
    return;
}

=item C<< $p->current_cash() >>

Returns the sum of cash available (may return a negative value if
"effet de levier" is used).

=cut
sub current_cash { $_[0]->{'cash'} }

=item C<< $p->current_evaluation() >>

Returns the evaluation of all the open positions in the portfolio.

=cut
sub current_evaluation {
    my ($self) = @_;

    my $eval = 0;
    foreach my $position ($self->list_open_positions)
    {
	if (! $position->is_marged)
	{
	    $eval += $self->{'position_evaluation'}{$position->id};
	}
    }
    return $eval;
}

=item C<< $p->current_marged_gains() >>

Returns the sum of gains (or losses if the number is negative) made with
marged positions.

=cut
sub current_marged_gains {
    my ($self) = @_;

    my $eval = 0;
    foreach my $position ($self->list_open_positions)
    {
	if ($position->is_marged)
	{
	    $eval += $self->{'position_marged_gains'}{$position->id};
	}
    }
    return $eval;
}

=item C<< $p->current_marged_investment() >>

Returns the sum of gains (or losses if the number is negative) made with
marged positions.

=cut
sub current_marged_investment {
    my ($self) = @_;

    my $eval = 0;
    foreach my $position ($self->list_open_positions)
    {
	if ($position->is_marged)
	{
	    $eval += $self->{'position_evaluation'}{$position->id};
	}
    }
    return $eval;
}


=item C<< my($cash, $evaluation, $gains) = $p->get_historic_evaluation($date) >>

Return the historic information (cash and portfolio evaluation) about the
portfolio.  

=cut
sub get_historic_evaluation {
    my ($self, $date) = @_;
    
    #WAR#  WARN  "the evaluation must exist for the given date" if ( exists $self->{'evaluation_history'}{$date});
    
    my @eval = @{$self->{'evaluation_history'}{$date}};
    if (wantarray)
    {
	return @eval;
    } else {
	# Marged investment is left out on purpose !
	my $sum = $eval[0] + $eval[1] + $eval[2];
	return $sum;
    }
}

=item C<< $p->has_historic_evaluation($date) >>

Returns true if an evaluation of the portfolio exists for the given date.

=cut
sub has_historic_evaluation {
    my ($self, $date) = @_;
    
    return exists $self->{'evaluation_history'}{$date};
}

=item C<< $p->list_pending_orders([$source]) >>

Returns the list of orders that are pending and that have been submitted
by the corresponding source. If source argument is missing (or undef),
returns all the pending orders.

=cut
sub list_pending_orders {
    my ($self, $source) = @_;
    
    if (defined($source)) {
	return grep { defined($_) && ($_->source eq $source) }
		    @{$self->{'pending_orders'}};
    } else {
	return grep { defined($_) } @{$self->{'pending_orders'}};
    }
}

=item C<< $p->list_open_positions([$source]) >>

Returns the list of positions that are open and that have been submitted
by the corresponding source. If source argument is missing (or undef),
returns all the open positions.

=cut
sub list_open_positions {
    my ($self, $source) = @_;
    
    if (defined($source)) {
	return grep { defined($_) && ($_->source eq $source) }
		    @{$self->{'open_positions'}};
    } else {
	return grep { defined($_) } @{$self->{'open_positions'}};
    }
}

=item C<< $p->get_position($code, $source) >>

Return the position (if any) corresponding to $code and $source.
This assumes that only one such position exists.

=cut
sub get_position {
    my ($self, $code, $source) = @_;

    my @res = grep { defined($_) && ($_->code eq $code) && 
		     ($_->source eq $source) }
		@{$self->{'open_positions'}};
    if (scalar(@res)) {
	return wantarray ? @res : $res[0];
    } else {
	return undef;
    }
}

=item C<< $p->list_history_positions($code, $source) >>

Return the list of historical positions corresponding to $code and $source.

=cut
sub list_history_positions {
    my ($self, $code, $source) = @_;

    return grep { defined($_) && ($_->code eq $code) && 
		     ($_->source eq $source) }
		@{$self->{'history'}};
}

=item C<< $p->set_initial_value() >>

Set the amount of money available initially on the portfolio.

=cut
sub set_initial_value {
    my ($self, $value) = @_;

    $self->{'initial_sum'} = $value;
    if (! $self->{'cash'})
    {
	$self->{'cash'} = $value;
    }
}

=item C<< $p->set_broker($broker) >>

Defines which broker to use for the calculation of order commissions and
annual account charge.

=cut
sub set_broker {
    my ($self, $broker) = @_;

    $self->{'broker'} = $broker;

    return;
}

=item C<< $p->get_order_cost($order) >>

Apply all broker rules and return the amount ask by the broker for the
given order.

=cut
sub get_order_cost {
    my ($self, $order) = @_;

    if (defined($self->{'broker'})) {
	my $cost = $self->{'broker'}->calculate_order_commission($order);
	return $cost;
    }
    return 0;
}

=item C<< $p->real_global_analysis() >>

=item C<< $p->real_analysis_by_code($code) >>

Analyzes the evolution of the portfolio. Either globally or for each
share individually.

Real analysis uses just the information provided. For a global analysis,
it needs an initial value for the portfolio.

The informations calculated are :

    - global gain/loss (sum & percentage)
    - number of winning trades
    - number of loosing trades
    - average loss (percentage)
    - average gain (percentage)
    - max gain in single trade (percentage)
    - max loss in single trade (percentage)
    - max global gain 
    - max global loss 
    - max draw down (biggest cumulated loss after a new high) (percentage)

=cut
sub real_global_analysis {
    my ($self) = @_;
    my $date2int = sub { 
	Finance::GeniusTrader::DateTime::map_date_to_time($_[0]->timeframe, $_[0]->open_date)
    };

    my $ana = $self->new_analysis();

    foreach (sort { &$date2int($a) <=> &$date2int($b) } @{$self->{'history'}})
    {
	$self->update_analysis($ana, $_);
    }

    return $self->return_analysis($ana);
}

sub real_analysis_by_code {
    my ($self, $code) = @_;
    my $date2int = sub { 
	Finance::GeniusTrader::DateTime::map_date_to_time($_[0]->timeframe, $_[0]->open_date)
    };

    my $ana = $self->new_analysis();

    foreach (sort { &$date2int($a) <=> &$date2int($b) } 
		    grep { $_->code eq $code } @{$self->{'history'}})
    {
	$self->update_analysis($ana, $_);
    }

    return $self->return_analysis($ana);
}

# Create the analysis hash
sub new_analysis {
    my ($self) = @_;
    my $ana = {
	"initial_sum" => $self->{'initial_sum'},
	map { $_ => 0 } 
	("gain", "nb_gain", "nb_loss", 
	 "expectancy", "sum_gain", "sum_loss", "cum_gain_pc",
	 "cum_loss_pc", "max_single_gain", "max_single_loss", "max_gain",
	 "max_loss", "max_draw_down", "draw_down_high", "draw_down_low",
	 "nb_orders", "sum_bought", "sum_sold", "commissions", 
	 "max_consec_gain", "max_consec_loss", "consec_gain",
	 "consec_loss")
    };
    $ana->{'cum_loss_pc'} = 1;
    $ana->{'cum_gain_pc'} = 1;
    return $ana;
}

# Update the analysis hash with a new operation
# This must be called with operation in chronological order
sub update_analysis {
    my ($self, $a, $o, $quantity_factor) = @_; # analysis, operation
    my ($diff, $variation, $draw_down) = (0, 0, 0);

    # Calculate the mean open/close price and the total quantity
 
    my $pstats = $o->stats($self, $quantity_factor);
    
    $a->{'nb_orders'} += $pstats->{'nb_orders'};
    $a->{'sum_bought'} += $pstats->{'bought'};
    $a->{'sum_sold'} += $pstats->{'sold'};
    $a->{'commissions'} += $pstats->{'cost'};

    # Calculate the gain for this position (set of operation)
    # $diff => in currency
    # $variation => in percentage
    
    $diff = $pstats->{'sold'} - $pstats->{'bought'} - $pstats->{'cost'};
    if ($o->is_long) {
	$variation = ($pstats->{'bought'} !=0) ? 
			($diff / $pstats->{'bought'}) : 0;
    } else {
	$variation = ($pstats->{'sold'} !=0) ? ($diff / $pstats->{'sold'}) : 0;
    }
	
    # Update the total gain
    $a->{'gain'} += $diff;

    # Check for new max_gain or max_loss
    if ($a->{'gain'} > $a->{'max_gain'}) {
	$a->{'max_gain'} = $a->{'gain'};
	$a->{'max_gain_date'} = $o->close_date;
    }
    if ($a->{'gain'} < $a->{'max_loss'}) {
	$a->{'max_loss'} = $a->{'gain'};
	$a->{'max_loss_date'} = $o->close_date;
    }
    
    # Check if we have a new max_draw_down
    $draw_down = 1 - (($a->{'initial_sum'} + $a->{'gain'}) / ($a->{'initial_sum'} + $a->{'max_gain'}));
    if ($draw_down > $a->{'max_draw_down'}) {
	$a->{'max_draw_down'} = $draw_down;
	$a->{'draw_down_high'} = $a->{'max_gain'};
	$a->{'draw_down_low'} = $a->{'gain'};
	$a->{'max_draw_down_date'} = $o->close_date;
    }
    
    # Stats on single trade
    if ($variation > 0) {
	$a->{'nb_gain'}++;
	$a->{'sum_gain'} += $diff;
	$a->{'cum_gain_pc'} *= (1 + $variation);
	if ($variation > $a->{'max_single_gain'}) {
	    $a->{'max_single_gain'} = $variation;
	    $a->{'max_single_gain_date'} = $o->close_date;
	}
	$a->{'consec_gain'}++;
	$a->{'consec_loss'} = 0;
	if ($a->{'consec_gain'} > $a->{'max_consec_gain'})
	{
	    $a->{'max_consec_gain'} = $a->{'consec_gain'};
	    $a->{'max_consec_gain_date'} = $o->close_date;
	}
    } else {
	$a->{'nb_loss'}++;
	$a->{'sum_loss'} += $diff;
	$a->{'cum_loss_pc'} *= (1 + $variation);
	if ($variation < $a->{'max_single_loss'}) {
	    $a->{'max_single_loss'} = $variation;
	    $a->{'max_single_loss_date'} = $o->close_date;
	}
	$a->{'consec_loss'}++;
	$a->{'consec_gain'} = 0;
	if ($a->{'consec_loss'} > $a->{'max_consec_loss'})
	{
	    $a->{'max_consec_loss'} = $a->{'consec_loss'};
	    $a->{'max_consec_loss_date'} = $o->close_date;
	}
    }
}

sub return_analysis {
    my ($self, $ana) = @_;
    my $average_loss = 0;
    my $average_gain = 0;
    my $win_loss_ratio = 0;
    my $profit_factor = 0;
    my $expectancy = 0;
    my $average_trade = 0;
    
    if ($ana->{'nb_loss'} != 0) {
	$average_loss = ($ana->{'cum_loss_pc'} ** (1 / $ana->{'nb_loss'})) - 1;
    }
    if ($ana->{'nb_gain'} != 0) {
	$average_gain = ($ana->{'cum_gain_pc'} ** (1 / $ana->{'nb_gain'})) - 1;
    }
    if ($ana->{'nb_loss'} + $ana->{'nb_gain'} != 0)
    {
	$win_loss_ratio = $ana->{'nb_gain'} / 
			  ($ana->{'nb_gain'} + $ana->{'nb_loss'});
	$average_trade = (1 + ($ana->{'gain'} / $ana->{'initial_sum'})) **
			 ( 1 / ($ana->{'nb_gain'} + $ana->{'nb_loss'})) - 1;
    }
    if ($average_loss != 0)
    {
	$profit_factor = $average_gain / ($average_loss * -1);
	$expectancy = $win_loss_ratio * $average_gain + (1 - $win_loss_ratio) * $average_loss;
    }
    else
    {
	$profit_factor = 999999;
	$expectancy = $win_loss_ratio * $average_gain;
    }

    # Calculate Vince's "R4" (Risk Of Ruin)
    # 
    # Example on system TFS with Alcatel :
    # There is a 19.2 % probability of the account falling 40 % below the start
    # equity (10 000 EUR) before it rises above 20 000 EUR.
    
    # Probability of a win
    my $PW = $win_loss_ratio;
    
    # Average winning trade
    my $AW = ($ana->{'nb_gain'} eq 0) ? 0 : $ana->{'sum_gain'} / $ana->{'nb_gain'};
    
    # Average losing trade
    my $AL = ($ana->{'nb_loss'} eq 0) ? 0 : $ana->{'sum_loss'} / $ana->{'nb_loss'};

    # Size of starting account
    my $Q = $ana->{'initial_sum'};

    # Quit trading and celebrate if account reaches this
    my $L = $ana->{'initial_sum'} * 2;

    # Drawdown to start equity that constitutes "ruin"
    my $G = 0.40;

    # Initialize the risk of ruin to 100 % before we calculate it, so that
    # the ratio is already set up if we have no winning trades...
    my $R4 = 1.0;
   
    # Calculate the risk or ruin only if we have some winning trades and
    # losing ones !
    if (($AW != 0) and ($AL != 0)) {
	my $a = sqrt( ($PW * ($AW / $Q) * ($AW / $Q)) + ((1.0 - $PW) * ($AL / $Q) * ($AL / $Q)) );
	my $z = (abs($AW / $Q) * $PW) - (abs($AL / $Q) * (1.0 - $PW));
	my $p = 0.5 * (1.0 + ($z / $a));
	my $U = $G / $a;
	my $c = (($L - ((1.0 - $G) * $Q)) / $Q) / $a;
	my $temp1 = exp($U * log((1.0 - $p) / $p));
	my $temp2 = exp($c * log((1.0 - $p) / $p));
	if ($temp2 != 1) {
	    $R4 = 1.0 - (($temp1 - 1.0) / ($temp2 - 1.0));
	} else {
	    $R4 = 0;
	}
    }

    # Set up the risk of ruin to 0 % if we don't have losing trades !
    $R4 = 0 if ($AL eq 0);

    return {
	"performance" => $ana->{'gain'} / $ana->{'initial_sum'},
	"max_performance" => $ana->{'max_gain'} / $ana->{'initial_sum'},
	"max_performance_date" => $ana->{'max_gain_date'},
	"min_performance" => $ana->{'max_loss'} / $ana->{'initial_sum'},
	"min_performance_date" => $ana->{'max_loss_date'},
	"max_draw_down" => $ana->{'max_draw_down'},
	"max_draw_down_date" => $ana->{'max_draw_down_date'},
	"nb_gain" => $ana->{'nb_gain'},
	"nb_loss" => $ana->{'nb_loss'},
	"win_loss_ratio" => $win_loss_ratio,
	"biggest_gain" => $ana->{'max_single_gain'},
	"biggest_gain_date" => $ana->{'max_single_gain_date'},
	"biggest_loss" => $ana->{'max_single_loss'},
	"biggest_loss_date" => $ana->{'max_single_loss_date'},
	"average_loss" => $average_loss,
	"average_gain" => $average_gain,
	"average_performance" => $average_trade,
	"profit_factor" => $profit_factor,
	"expectancy" => $expectancy,
	"global_gain" => $ana->{'gain'},
	"gross_gain" => $ana->{'gain'} + $ana->{'commissions'},
	"sum_of_gain" => $ana->{'sum_gain'},
	"sum_of_loss" => $ana->{'sum_loss'},
	"max_consecutive_winner" => $ana->{'max_consec_gain'},
	"max_consecutive_winner_date" => $ana->{'max_consec_gain_date'},
	"max_consecutive_loser" => $ana->{'max_consec_loss'},
	"max_consecutive_loser_date" => $ana->{'max_consec_loss_date'},
	"risk_of_ruin" => $R4
    };
}

=pod

=back

=cut
1;
