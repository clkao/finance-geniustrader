package Finance::GeniusTrader::Dependency;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

#ALL#  use Log::Log4perl qw(:easy);

=head1 NAME

Finance::GeniusTrader::Dependency - A dependency system for indicators/signals/systems.

=head1 DESCRIPTION

This module is inheritated by any object which needs a Dependency
mechanism. That's why it's listed in @ISA of Finance::GeniusTrader::Indicators, Finance::GeniusTrader::Signals,
GT:Systems and several other modules ...

=over

=item C<< $object->add_indicator_dependency($indic, $nbdays) >>

=item C<< $object->add_signal_dependency($signal, $nbdays) >>

=item C<< $object->add_prices_dependency($nbdays) >>

=item C<< $object->add_arg_dependency($argnum, $nbdays) >>

=item C<< $object->add_volatile_indicator_dependency($indic, $nbdays) >>

=item C<< $object->add_volatile_signal_dependency($signal, $nbdays) >>

=item C<< $object->add_volatile_prices_dependency($nbdays) >>

=item C<< $object->add_volatile_arg_dependency($argnum, $nbdays) >>

Add a dependency on a precise indicator or signal. The current object
needs nbdays of history (current day included) on the given indicator
or signal to be able to produce a result. A prices dependency indicates
the number of days of history prices

A volatile dependency will be removed by $object->remove_volatile_dependencies().
It is used for adding last-minute dependencies whose values are known late
because they are computed based on other data.

=cut
sub add_indicator_dependency {
    my ($self, $indicator, $nbdays) = @_;
    #ERR#  ERROR  "Bad dependency" if ( ref($indicator) =~ /Finance::GeniusTrader::Indicators/);

    if ($self->{'indic_depends'})
    {
	push @{$self->{'indic_depends'}}, { 'indicator' => $indicator,
					    'nbdays' => $nbdays };
    } else {
	$self->{'indic_depends'}[0] = { 'indicator' => $indicator,
					'nbdays' => $nbdays };
    }

    return;
}
sub add_signal_dependency {
    my ($self, $signal, $nbdays) = @_;
    #ERR#  ERROR  "Bad dependency" if ( ref($signal) =~ /Finance::GeniusTrader::Signals/);
    
    if ($self->{'sig_depends'})
    {
	push @{$self->{'sig_depends'}}, { 'signal' => $signal,
					  'nbdays' => $nbdays };
    } else {
	$self->{'sig_depends'}[0] = { 'signal' => $signal,
				      'nbdays' => $nbdays };
    }

    return;
}
sub add_prices_dependency {
    my ($self, $nbdays) = @_;

    if (defined($self->{'price_depends'}))
    {
	$self->{'price_depends'} = ($nbdays > $self->{'price_depends'}) ?
				    $nbdays : $self->{'price_depends'};
    } else {
	$self->{'price_depends'} = $nbdays;
    }
    
    return;
}
sub add_arg_dependency {
    my ($self, $argnum, $nbdays) = @_;
    my $object = $self->{'args'}->get_arg_object($argnum);
    ref($object) =~ /^Finance::GeniusTrader::Indicators/ and $self->add_indicator_dependency($object, $nbdays);
    ref($object) =~ /^Finance::GeniusTrader::Signals/ and $self->add_signal_dependency($object, $nbdays);
    return;
}
sub add_volatile_indicator_dependency {
    my ($self, $indicator, $nbdays) = @_;
    #ERR#  ERROR  "Bad dependency" if ( ref($indicator) =~ /Finance::GeniusTrader::Indicators/);
    
    if ($self->{'volatile_indic_depends'})
    {
	push @{$self->{'volatile_indic_depends'}}, { 'indicator' => $indicator,
					    'nbdays' => $nbdays };
    } else {
	$self->{'volatile_indic_depends'}[0] = { 'indicator' => $indicator,
					'nbdays' => $nbdays };
    }

    return;
}
sub add_volatile_signal_dependency {
    my ($self, $signal, $nbdays) = @_;
    #ERR#  ERROR  "Bad dependency" if ( ref($signal) =~ /Finance::GeniusTrader::Signals/);

    if ($self->{'volatile_sig_depends'})
    {
	push @{$self->{'volatile_sig_depends'}}, { 'signal' => $signal,
					  'nbdays' => $nbdays };
    } else {
	$self->{'volatile_sig_depends'}[0] = { 'signal' => $signal,
				      'nbdays' => $nbdays };
    }

    return;
}
sub add_volatile_prices_dependency {
    my ($self, $nbdays) = @_;

    if (defined($self->{'volatile_price_depends'}))
    {
	$self->{'volatile_price_depends'} = ($nbdays > $self->{'volatile_price_depends'}) ?
				    $nbdays : $self->{'volatile_price_depends'};
    } else {
	$self->{'volatile_price_depends'} = $nbdays;
    }
    
    return;
}
sub add_volatile_arg_dependency {
    my ($self, $argnum, $nbdays) = @_;
    my $object = $self->{'args'}->get_arg_object($argnum);
    ref($object) =~ /^Finance::GeniusTrader::Indicators/ and $self->add_volatile_indicator_dependency($object, $nbdays);
    ref($object) =~ /^Finance::GeniusTrader::Signals/ and $self->add_volatile_signal_dependency($object, $nbdays);
    return;
}

=item C<< $object->get_prices_dependency() >>

=item C<< $object->get_signal_dependencies() >>

=item C<< $object->get_indicator_dependencies() >>

Return the dependency or list of dependencies.

=cut
sub get_prices_dependency {
    my ($self) = @_;
    my $max = 1;
    
    if ($self->{'price_depends'})
    {
	$max = $self->{'price_depends'};
    }
    if ($self->{'volatile_price_depends'})
    {
	my $v = $self->{'volatile_price_depends'};
	$max = ($v > $max) ? $v : $max;
    }
    return $max;
}
sub get_indicator_dependencies {
    my ($self) = @_;
    my @dep = ();
    push @dep, @{$self->{'indic_depends'}} if (defined($self->{'indic_depends'}));
    push @dep, @{$self->{'volatile_indic_depends'}} if (defined($self->{'volatile_indic_depends'}));
    return @dep;
}
sub get_signal_dependencies {
    my ($self) = @_;
    my @dep = ();
    push @dep, @{$self->{'sig_depends'}} if (defined($self->{'sig_depends'}));
    push @dep, @{$self->{'volatile_sig_depends'}} if (defined($self->{'volatile_sig_depends'}));
    return @dep;
}
   
=item C<< $object->remove_volatile_dependencies() >>

Removes all volatile dependencies.

=cut
sub remove_volatile_dependencies {
    my ($self) = @_;
    $self->{'volatile_indic_depends'} = [];
    $self->{'volatile_sig_depends'} = [];
    $self->{'volatile_prices_depends'} = 0;
    return;
}

=item C<< $object->days_required >>

Returns the number of days required so that the object can produce a result.

=cut
sub days_required {
    my ($self) = @_;

    return $self->{_days_required_cache}
        if $self->{_days_required_cache};

    my $max = $self->get_prices_dependency;
    
    foreach ($self->get_indicator_dependencies())
    {
	my $tmp = $_->{'indicator'}->days_required + $_->{'nbdays'} - 1;
	$max = ($tmp > $max) ? $tmp : $max;
    }
    foreach ($self->get_signal_dependencies())
    {
	my $tmp = $_->{'signal'}->days_required + $_->{'nbdays'} - 1;
	$max = ($tmp > $max) ? $tmp : $max;
    }

    return $self->{_days_required_cache} = $max;
}

=item C<< ($first, $last) = $object->update_interval($calc, $first, $last) >>

Check the limits of the interval. Return new limits. The interval
is contained in the first interval but all days will produce a result.
The new interval may be equal to the given interval.

=cut
sub update_interval {
    my ($self, $calc, $first, $last) = @_;

    if ($first + 1 < $self->days_required)
    {
	$first = $self->days_required - 1;
    }
    if ($last + 1 > $calc->prices->count)
    {
	$last = $calc->prices->count - 1;
    }

    return ($first, $last);
}

=item C<< $object->check_dependencies($calc, $i) >>

=item C<< $object->check_dependencies_interval($calc, $first, $last) >>

Check that there is enough data available. If there isn't return false.
Otherwise make sure the required data are computed and return true.

=cut
sub check_dependencies {
    my ($self, $calc, $i) = @_;

    if ($i + 1 < $self->days_required)
    {
	return 0;
    }
    if (! $self->dependencies_are_available($calc, $i))
    {
	$self->compute_dependencies($calc, $i);
    } else {
	return 1;
    }
    return $self->dependencies_are_available($calc, $i);
}
sub check_dependencies_interval {
    my ($self, $calc, $first, $last) = @_;
    
    if ($first + 1 < $self->days_required)
    {
	return 0;
    }
    if (! $self->dependencies_are_available_interval($calc, $first, $last))
    {
	$self->compute_dependencies_interval($calc, $first, $last);
    } else {
	return 1;
    }
    return $self->dependencies_are_available_interval($calc, $first, $last);
}

=item C<< $object->dependencies_are_available($calc, $i) >>

=item C<< $object->dependencies_are_available_interval($calc, $first, $last) >>

Check if all dependencies have been computed.

=cut
# XXX: it would be besser if we could check for the availability
# of the interval instead of checking each day
#
# The function does assume that if the first value provided by
# the indicator is available, then all others are available
sub dependencies_are_available {
    my ($self, $calc, $i) = @_;
    
    my $indic = $calc->indicators;
    # Availibility of indicators
    foreach ($self->get_indicator_dependencies())
    {
	my $name = $_->{'indicator'}->get_name;
        
	for (my $n = $i - $_->{'nbdays'} + 1; $n <= $i; $n++)
	{
	    if (! $indic->is_available($name, $n))
	    {
		return 0;
	    }
	}
    }

    # Availability of signals
    foreach ($self->get_signal_dependencies())
    {
	my $name = $_->{'signal'}->get_name;
	for (my $n = $i - $_->{'nbdays'} + 1; $n <= $i; $n++)
	{
	    if (! $calc->signals->is_available($name, $n))
	    {
		return 0;
	    }
	}
    }
    return 1;
}
sub dependencies_are_available_interval {
    my ($self, $calc, $first, $last) = @_;
    
    # Availibility of indicators
    foreach ($self->get_indicator_dependencies())
    {
	my $name = $_->{'indicator'}->get_name;
	for (my $n = $first - $_->{'nbdays'} + 1; $n <= $last; $n++)
	{
	    if (! $calc->indicators->is_available($name, $n))
	    {
		return 0;
	    }
	}
    }

    # Availability of signals
    foreach ($self->get_signal_dependencies())
    {
	my $name = $_->{'signal'}->get_name;
	for (my $n = $first - $_->{'nbdays'} + 1; $n <= $last; $n++)
	{
	    if (! $calc->signals->is_available($name, $n))
	    {
		return 0;
	    }
	}
    }
   
    return 1;
}

=item C<< $object->compute_dependencies($calc, $i) >>

=item C<< $object->compute_dependencies_interval($calc, $first, $last) >>

Calculate all dependent indicators and detect all dependent signals.

=cut
sub compute_dependencies {
    my ($self, $calc, $i) = @_;

    # Compute indicators
    foreach ($self->get_indicator_dependencies())
    {
	#DEB#  DEBUG  "Compute dependencies for $self : $_->{'indicator'}\n";
	if ($_->{'nbdays'} > 1)
	{
	    $_->{'indicator'}->calculate_interval($calc,
					    $i - $_->{'nbdays'} + 1, $i);
	} else {
	    $_->{'indicator'}->calculate($calc, $i);
	}
    }
		
    # Compute signals
    foreach ($self->get_signal_dependencies())
    {
	#DEB#  DEBUG  "Compute dependencies for $self : $_->{'signal'}\n";
	if ($_->{'nbdays'} > 1)
	{
	    $_->{'signal'}->detect_interval($calc,
					    $i - $_->{'nbdays'} + 1, $i);
	} else {
	    $_->{'signal'}->detect($calc, $i);
	}
    }

    return;
}
sub compute_dependencies_interval {
    my ($self, $calc, $first, $last) = @_;
    
    # Compute indicators
    foreach ($self->get_indicator_dependencies())
    {
	#DEB#  DEBUG  "Compute dependencies for $self : $_->{'indicator'}\n";
	$_->{'indicator'}->calculate_interval($calc,
				    $first - $_->{'nbdays'} + 1, $last);
    }
		
    # Compute signals
    foreach ($self->get_signal_dependencies())
    {
	#DEB#  DEBUG  "Compute dependencies for $self : $_->{'signal'}\n";
	$_->{'signal'}->detect_interval($calc, 
				    $first - $_->{'nbdays'} + 1, $last);
    }

    return;
}

=pod

=back

=cut
1;
