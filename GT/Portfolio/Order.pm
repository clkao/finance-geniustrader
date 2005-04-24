package GT::Portfolio::Order;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

our @ISA = qw(GT::Serializable);

use strict;
#ALL# use Log::Log4perl qw(:easy);
use GT::Prices;
use GT::Serializable;

=head1 NAME

GT::Portfolio::Order - An order within the portfolio

=head1 DESCRIPTION

=head2 Internal structure

 {
    "order" => "B",	    # Buy/Sell
    "type" => "L",	    # Limited|Stop|APD|ATP|TR
    "code" => "13000",
    "quantity" => 100,
    "price" => "12.4",      # Main price
    "price2" => "12.6",     # Second limit (if needed)
    "source" => "Trend",    # Trading system that opened the position
			    # maybe "manual"
    "date" => "2001-07-01", # date of submission
    "validity" => "2001-07-02", # valable until this day
    "no_discard" => 1,	    # don't remove the order automatically next day
    "id" => 123		    # id automatically assigned when added to
			    # the portfolio
 }

=head2 Functions

=over

=item C<< $o = GT::Portfolio::Order->new; >>

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { };
    
    bless $self, $class;
    return $self;
}

=item C<< $o->set_sell_order() >>

=item C<< $o->set_buy_order() >>

=item C<< $o->is_sell_order() >>

=item C<< $o->is_buy_order() >>


=cut
sub set_sell_order { $_[0]->{'order'} = 'S'; }
sub set_buy_order  { $_[0]->{'order'} = 'B'; }
sub is_sell_order  { $_[0]->{'order'} eq 'S' }
sub is_buy_order   { $_[0]->{'order'} eq 'B' }

=item C<< $o->set_type($type) >>

=item C<< $o->get_type() >>

Manage the type of the order. Valid types are :

=over 8

=item M

Market price

=item L

Limit

=item S

Stop

=item APD

A plage de déclenchement (french market only)

=item TR

Tout ou rien (french market)

=item ATP

A tout prix (french market)

=back

=cut
sub set_type {
    my ($self, $type) = @_;
    #ERR# ERROR "valid order type" unless ($type =~ /^(M|L|S|APD|ATP|TR)$/);
    $self->{'type'} = $type;
}
sub type { $_[0]->{'type'} }

=item C<< $o->set_type_{limited,market_price,stop,stop_limited}() >>

=item C<< $o->is_type_{limited,market_price,stop,stop_limited}() >>

Change/checks the type of the order.

=cut
sub set_type_limited      { $_[0]->{'type'} = 'L'; }
sub set_type_market_price { $_[0]->{'type'} = 'M'; }
sub set_type_stop         { $_[0]->{'type'} = 'S'; }
sub set_type_stop_limited { $_[0]->{'type'} = 'APD'; }

sub set_type_theoric_at_open   { $_[0]->{'type'} = 'OPEN'; }
sub set_type_theoric_at_high   { $_[0]->{'type'} = 'HIGH'; }
sub set_type_theoric_at_low    { $_[0]->{'type'} = 'LOW'; }
sub set_type_theoric_at_close  { $_[0]->{'type'} = 'CLOSE'; }
sub set_type_theoric_at_signal { $_[0]->{'type'} = 'SIGNAL'; }

sub is_type_limited       { $_[0]->{'type'} eq 'L' }
sub is_type_market_price  { $_[0]->{'type'} eq 'M' }
sub is_type_stop          { $_[0]->{'type'} eq 'S' }
sub is_type_stop_limited  { $_[0]->{'type'} eq 'APD' }

sub is_type_theoric_at_open   { $_[0]->{'type'} eq 'OPEN' }
sub is_type_theoric_at_high   { $_[0]->{'type'} eq 'HIGH' }
sub is_type_theoric_at_low    { $_[0]->{'type'} eq 'LOW' }
sub is_type_theoric_at_close  { $_[0]->{'type'} eq 'CLOSE' }
sub is_type_theoric_at_signal { $_[0]->{'type'} eq 'SIGNAL' }

=item C<< $o->set_code($code) >>

=item C<< $o->code() >>

Set/get the symbol of the traded share.

=cut
sub set_code {
    my ($self, $code) = @_;
    $self->{'code'} = $code;
}
sub code { $_[0]->{'code'} }

=item C<< $o->set_quantity($quantity) >>

=item C<< $o->quantity() >>

Set/get the quantity of shares.

=cut
sub set_quantity {
    my ($self, $q) = @_;
    $self->{'quantity'} = $q;
}
sub quantity { $_[0]->{'quantity'} }

=item C<< $o->set_price($price) >>

=item C<< $o->price() >>

=item C<< $o->set_second_price($price) >>

=item C<< $o->second_price() >>

Set/get the prices on the order.

=cut
sub set_price {
    my ($self, $price) = @_;
    $self->{'price'} = $price;
}
sub set_second_price {
    my ($self, $price) = @_;
    $self->{'price2'} = $price;
}
sub price        { $_[0]->{'price'} }
sub second_price { $_[0]->{'price2'} }

=item C<< $o->set_source($source) >>

=item C<< $o->source() >>


=cut
sub set_source {
    my ($self, $source) = @_;
    $self->{'source'} = $source;
}
sub source { $_[0]->{'source'} }

=item C<< $o->set_submission_date($date) >>

=item C<< $o->submissiont_date() >>


=cut
sub set_submission_date {
    my ($self, $date) = @_;
    $self->{'date'} = $date;
}
sub submission_date { $_[0]->{'date'} }

=item C<< $o->set_indicative_stop($price) >>

=item C<< $o->indicative_stop() >>


=cut
sub set_indicative_stop {
    my ($self, $price) = @_;
    $self->{'indicative_stop'} = $price;
}
sub indicative_stop { $_[0]->{'indicative_stop'} }

=item C<< $o->set_not_discardable() >>

=item C<< $o->set_discardable() >>

=item C<< $o->discardable() >>

A normal order has a validity of one period (ie one day usually). If
you want to place an order that should be kept until it's executed
(a close on target for example) you need to modify the order
by calling this function on it.

=cut
sub set_not_discardable { $_[0]->{'no_discard'} = 1 }
sub set_discardable { $_[0]->{'no_discard'} = 0 }
sub discardable { 
    my ($self) = @_;
    if (defined($self->{'no_discard'}) && $self->{'no_discard'})
    {
	return 0;
    }
    return 1;
}

=item C<< $o->set_id($id) >>

=item C<< $o->id() >>


=cut
sub set_id {
    my ($self, $id) = @_;
    $self->{'id'} = $id;
}
sub id { $_[0]->{'id'} }

=item C<< $o->set_attribute($key, [ $value ]); >>

=item C<< $o->has_attribute($key); >>

=item C<< $o->attribute($key); >>

=item C<< $o->delete_attribute($key); >>

An order can have "attributes" associated to keep track of its status
in various strategies. has_attribute returns only true if the attribute
exists (whatever its value is). attribute returns the attribute value if
it exists or undef otherwise.

=cut
sub set_attribute {
    my ($self, $key, $value) = @_;
    $value = 1 if (! defined($value));
    $self->{'attributes'}{$key} = $value;
}
sub has_attribute {
    my ($self, $key) = @_;
    return 1 if (exists $self->{'attributes'}{$key});
    return 0;
}
sub attribute {
    my ($self, $key) = @_;
    if (exists $self->{'attributes'}{$key})
    {
	return $self->{'attributes'}{$key};
    }
    return undef;
}
sub delete_attribute {
    my ($self, $key) = @_;
    delete $self->{'attributes'}{$key};
}

=item C<< $o->set_timeframe($timeframe) >>

=item C<< $o->timeframe() >>

Set and return the timeframe associated to this order.

=cut
sub set_timeframe { $_[0]->{'timeframe'} = $_[1] }
sub timeframe { $_[0]->{'timeframe'} }

=item C<< $o->set_marged() >>

=item C<< $o->set_not_marged() >>

=item C<< $o->is_marged() >>

A marged order will not cost cash since the cash is "rented" until
the position is closed.

=cut
sub set_marged     { $_[0]->{'marged'} = 1 }
sub set_not_marged { $_[0]->{'marged'} = 0 }
sub is_marged      { defined($_[0]->{'marged'}) && $_[0]->{'marged'} }

=item C<< $o->is_executed($calc, $i) >>

Returns the price of execution if the order has been executed. Otherwise
returns 0.

=cut
sub is_executed {
    my ($self, $calc, $i) = @_;

    my $prices = $calc->prices->at($i);
    my $price = -1;

    if ($self->is_type_market_price) {
	# Market Price
	$price = $prices->[$FIRST];
    } elsif ($self->is_type_theoric_at_open) {
	# Market Open
	$price = $prices->[$OPEN];
    } elsif ($self->is_type_theoric_at_high) {
	# Market High
	$price = $prices->[$HIGH];
    } elsif ($self->is_type_theoric_at_low) {
	# Market Low
	$price = $prices->[$LOW];
    } elsif ($self->is_type_theoric_at_close) {
	# Market Close
	$price = $prices->[$CLOSE];
    } elsif ($self->is_type_theoric_at_signal) {
	# At Signal Closing Price
	$price = $calc->prices->at($i - 1)->[$CLOSE] if ($i >= 1);
    } elsif ($self->is_type_limited) {
	# At limited price
	if (($self->price >= $prices->[$LOW]) &&
	    ($self->price <= $prices->[$HIGH]))
	{
	    $price = $self->price;
	} else 
	{
	    if ($self->is_buy_order && ($self->price > $prices->[$HIGH]))
	    {
		$price = $prices->[$HIGH];
	    } elsif ($self->is_sell_order && ($self->price < $prices->[$LOW]))
	    {
		$price = $prices->[$LOW];
	    }
	}	
    } elsif ($self->is_type_stop) {
	# On stop (conditional order)
	if (($self->is_buy_order) &&
	    ($prices->[$HIGH] >= $self->price))
	{
	    $price = ($prices->[$FIRST] > $self->price) ?
		      $prices->[$FIRST] : $self->price;
	} elsif (($self->is_sell_order) &&
		 ($prices->[$LOW] <= $self->price))
	{
	    $price = ($prices->[$FIRST] < $self->price) ?
		      $prices->[$FIRST] : $self->price;
	}
    } elsif ($self->is_type_stop_limited) {
	# On stop (conditional order)
	if (($self->is_buy_order) &&
	    ($prices->[$HIGH] >= $self->price) &&
	    ($prices->[$LOW] <= $self->second_price))
	{
	    $price = ($prices->[$HIGH] < $self->second_price) ?
		      $prices->[$HIGH] : $self->second_price;
	} elsif (($self->is_sell_order) &&
		 ($prices->[$LOW] <= $self->price) &&
		 ($prices->[$HIGH] >= $self->second_price))
	{
	    $price = ($prices->[$LOW] > $self->second_price) ?
		      $prices->[$LOW] : $self->second_price;
	}
    } else {
	die "Order type $self->{'type'} not managed by is_executed\n";
    }
    
    $price = "0E0" if (! $price);     # Return 0 but true
    $price = "0"   if ($price == -1); # Return false

    return $price;
}

=pod

=back

=cut
1;
