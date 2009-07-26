package Finance::GeniusTrader::Systems;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT %OBJECT_REPOSITORY);

require Exporter;
@ISA = qw(Exporter Finance::GeniusTrader::Dependency);
@EXPORT = qw(&build_object_name &manage_object);

use Finance::GeniusTrader::Registry;
use Finance::GeniusTrader::Dependency;
use Finance::GeniusTrader::OrderFactory::MarketPrice;
#ALL#  use Log::Log4perl qw(:easy);
use Finance::GeniusTrader::ArgsTree;

=head1 NAME

Finance::GeniusTrader::Systems - 

=head1 DESCRIPTION

Trading systems are systems that decide what to buy and sell at which
prices and so on. 

A system will propose buy/sell orders. The day after, those orders will
be either cancelled or confirmed. If the order is confirmed, then a
position is considered open. An open position will then be managed by
a close strategy.

=over

=item C<< $system->long_signal($calc, $i) >>
=item C<< $system->short_signal($calc, $i) >>

The system can generate 2 signals (buy or sell). A signal is an
intent to buy or sell. Those functions should be overriden by the specific
system.

=cut
sub long_signal {
    my ($self, $calc, $i) = @_;
    
    return 0 if (! $self->check_dependencies($calc, $i));

    if (defined($self->{'long_signal'}))
    {
	return $calc->signals->get($self->{'long_signal'}->get_name, $i);
    }
    return 0;
}
sub short_signal {
    my ($self, $calc, $i) = @_;
    
    return 0 if (! $self->check_dependencies($calc, $i));

    if (defined($self->{'short_signal'}))
    {
	return $calc->signals->get($self->{'short_signal'}->get_name, $i);
    }
    return 0;
}

=item C<< $system->set_long_signal() >>

=item C<< $system->set_short_signal() >>

Facility function to set which signal is used to generate buy/sell signal.
They are meant to be used in initialize only if long_signal and short_signal
are not overriden.

=cut
sub set_long_signal {
    my ($self, $signal) = @_;
    $self->{'long_signal'} = $signal;
}
sub set_short_signal {
    my ($self, $signal) = @_;
    $self->{'short_signal'} = $signal;
}

=item C<< $system->precalculate_all($calc) >>
=item C<< $system->precalculate_interval($calc, $first, $last) >>

If you run a system on a long period of time you may want to precalculate
all the indicators in order to benefit of possible optimizations. This
is the role of those 2 functions.

=cut
# Helper functions to optimize calculations
sub precalculate_all {
    my ($self, $calc) = @_;
    $self->precalculate_interval($calc, 0, $calc->prices->count - 1);
    return;
}
sub precalculate_interval {
    my ($self, $calc, $first, $last) = @_;
    # Can do nothing, I don't know which indicators are used
    # This function must be overrident by specific systems
    return;
}

=item C<< $system->default_order_factory() >>

Return an object OrderFactory that can be used if no other objects was
to be used.

=cut
sub default_order_factory {
    return Finance::GeniusTrader::OrderFactory::MarketPrice->new;
}

# Default functions so that they are not mandatory
sub initialize              { 1; }

=back

=head2 Functions to manage a repository of systems

  Finance::GeniusTrader::Systems::get_registered_object($name);
  Finance::GeniusTrader::Systems::register_object($name, $object);
  Finance::GeniusTrader::Systems::get_or_register_object($name, $object);
  Finance::GeniusTrader::Systems::manage_object(\@NAMES, $object, $class, $args, $key);

=over

=cut
sub get_registered_object {
    Finance::GeniusTrader::Registry::get_registered_object(\%OBJECT_REPOSITORY, @_);
}
sub register_object {
    Finance::GeniusTrader::Registry::register_object(\%OBJECT_REPOSITORY, @_);
}
sub get_or_register_object {
    Finance::GeniusTrader::Registry::get_or_register_object(\%OBJECT_REPOSITORY, @_);
}
sub manage_object {
    Finance::GeniusTrader::Registry::manage_object(\%OBJECT_REPOSITORY, @_);
}

=item C<< Finance::GeniusTrader::Systems::Module->new($args) >>

Create a new Systems with the given arguments. $args is optional.

=cut
sub new {
    my ($type, $args) = @_;
    my $class = ref($type) || $type;

    no strict "refs";
    
    my $self = { };
    if (defined($args)) {
	if ( $#{$args} < $#{"$class\::DEFAULT_ARGS"} ) {
	    for (my $n=($#{$args}+1); $n<=$#{"$class\::DEFAULT_ARGS"}; $n++) {
		push @{$args}, ${"$class\::DEFAULT_ARGS"}[$n];
	    }
	}
	$self->{'args'} = Finance::GeniusTrader::ArgsTree->new(@{$args});
    } elsif (defined (@{"$class\::DEFAULT_ARGS"})) {
	$self->{'args'} = Finance::GeniusTrader::ArgsTree->new(@{"$class\::DEFAULT_ARGS"});
    } else {
	$self->{'args'} = Finance::GeniusTrader::ArgsTree->new(); # no args
    }

    return manage_object(\@{"$class\::NAMES"}, $self, $class, $self->{'args'},'');
}

=back
=cut
1;
