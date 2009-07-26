package Finance::GeniusTrader::Calculator;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use Finance::GeniusTrader::CacheValues;

=head1 NAME

Finance::GeniusTrader::Calculator - All data (of a single share) used for calculations

=head1 DESCRIPTION

This is a facility object to ease the collaboration between Finance::GeniusTrader::Prices
and Finance::GeniusTrader::CacheValues. It contains the prices (Finance::GeniusTrader::Prices),
and the result of various indicators and signals within two Finance::GeniusTrader::CacheValues
object. This object is manipulated by all the indicators, signals and
systems.

A calculator can contain the same serie of prices but indexed on different
time frames.

=over

=item C<< my $c = Finance::GeniusTrader::Calculator->new($prices [, $code]) >>

Create a new Finance::GeniusTrader::Calculator object with $prices used for
calculations. The calculator is associated to share named $code.

=item C<< $c->prices() >>

=item C<< $c->indicators() >>

=item C<< $c->signals() >>

Return the corresponding object of the current timeframe.

=item C<< $c->prices_on_timeframe($timeframe) >>

=item C<< $c->indicators_on_timeframe($timeframe) >>

=item C<< $c->signals_on_timeframe($timeframe) >>

Return the corresponding object of the indicated timeframe. Learn
more about the timeframes in Finance::GeniusTrader::DateTime.

=item C<< $c->set_code($code) >>

Sets the code of the share which datas are stored in this object.

=item C<< $c->code() >>

Returns the code of the share associated with this object.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $prices = shift;
    my $code = shift || "";
    
    my $self = { 'code' => $code, 'tf' => {} };
    
    $self->{'tf'}{$prices->timeframe}{'prices'} = $prices;
    $self->{'tf'}{$prices->timeframe}{'indics'} = Finance::GeniusTrader::CacheValues->new;
    $self->{'tf'}{$prices->timeframe}{'signals'} = Finance::GeniusTrader::CacheValues->new;
    
    bless $self, $class;
    
    $self->set_current_timeframe($prices->timeframe);
    
    return $self;
}

sub set_code {
    my ($self, $code) = @_;
    $self->{'code'} = $code;
}

sub code { $_[0]->{'code'} }

sub prices     { $_[0]->{'_prices'}  }
sub indicators { $_[0]->{'_indics'}  }
sub signals    { $_[0]->{'_signals'} }

sub prices_on_timeframe     { $_[0]->{'tf'}{$_[1]}{'prices'} }
sub indicators_on_timeframe { $_[0]->{'tf'}{$_[1]}{'indics'} }
sub signals_on_timeframe    { $_[0]->{'tf'}{$_[1]}{'signals'} }

=item C<< $calc->set_current_timeframe($timeframe) >>

Changes the current timeframe to the indicated one. If the timeframe
doesn't exist, it tries to create it. Returns 1 on success and 0 on
failure.

=item C<< $calc->current_timeframe() >>

Returns the current timeframe.

=cut
sub set_current_timeframe {
    my ($self, $tf) = @_;
    if (exists $self->{'tf'}{$tf})
    {
	$self->{'_prices'} = $self->{'tf'}{$tf}{'prices'};
	$self->{'_indics'} = $self->{'tf'}{$tf}{'indics'};
	$self->{'_signals'} = $self->{'tf'}{$tf}{'signals'};
	return 1;
    } else {
	if ($self->create_timeframe($tf))
	{
	    $self->{'_prices'} = $self->{'tf'}{$tf}{'prices'};
	    $self->{'_indics'} = $self->{'tf'}{$tf}{'indics'};
	    $self->{'_signals'} = $self->{'tf'}{$tf}{'signals'};
	    return 1;
	}
	return 0;
    }
}
sub current_timeframe { $_[0]->prices->timeframe }

=item C<< $calc->create_timeframe($timeframe) >>

Create the given timeframe with an other serie of prices available in the
calculator. Returns 1 on success and 0 on failure.

=cut
sub create_timeframe {
    my ($self, $tf) = @_;
    # Sort the timeframe from the lowest to the biggest
    # So the first one is the lowest that can build all the bigger
    my @tfs = $self->available_timeframe;
    # Only if possible
    if ($self->{'tf'}{$tfs[0]}{'prices'}->timeframe < $tf)
    {
	my $new = $self->{'tf'}{$tfs[0]}{'prices'}->convert_to_timeframe($tf);
	$self->{'tf'}{$tf}{'prices'} = $new;
	$self->{'tf'}{$tf}{'indics'} = Finance::GeniusTrader::CacheValues->new;
	$self->{'tf'}{$tf}{'signals'} = Finance::GeniusTrader::CacheValues->new;

	# If we udpated the current timeframe, then let's sync it
	if ($self->current_timeframe == $tf)
	{
	    $self->set_current_timeframe($tf);
	}
	return 1;
    }
    return 0;
}

=item C<< $calc->available_timeframe() >>

Returns the sorted list of available timeframes.

=cut
sub available_timeframe {
    my ($self) = @_;
    return sort { $a <=> $b } keys %{$self->{'tf'}};
}

=item C<< $calc->timeframe_is_available() >>

Returns true if the given timeframe is available in the calculator.
Otherwise returns false.

=cut
sub timeframe_is_available {
    my ($self, $tf) = @_;
    if (exists $self->{'tf'}{$tf})
    {
	return 1;
    }
    return 0;
}

=pod

=back

=cut
1;
