package Finance::GeniusTrader::Signals;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(%OBJECT_REPOSITORY @ISA @EXPORT);

require Exporter;
@ISA = qw(Exporter Finance::GeniusTrader::Dependency);
@EXPORT = qw(&build_object_name &manage_object);

use Finance::GeniusTrader::Registry;
use Finance::GeniusTrader::Dependency;

=head1 NAME

Finance::GeniusTrader::Signals - Base module for all signals

=head1 DESCRIPTION

=head2 Overview

Signals are objects that returns true/false for each quotation. This
value doesn't have any other direct meaning (ie it's not buy/sell).
However those results will probably be used by trading systems (in
cunjunction with other informations) to decide what to do
(buy/sell/update a stop/nothing).

=head2 Detailed description

=over

=item C<< my $sig = Finance::GeniusTrader::Signals::AnExample->new([ @args ]) >>

Create a signal object with the appropriate parameters.

=item C<< $sig->get_name or $sig->get_name($i) >>

Get the name of the signal. If the signal returns several values,
you can get the name corresponding to any value, you just have to
precise in the parameters the index of the value that you're interested
in.

=item C<< $sig->get_nb_values >>

Return the number of different values produced by this signal that are
available for use.

=item C<< $sig->initialize() >>

This callback function is called at creating time. Since the "new" function
is inherited, you should do the initialization via this function.

=item C<< $sig->detect($calc, $i) >>

Stores the value of the signal for the day $i.

=item C<< $sig->detect_interval($calc, $first, $last) >>

Stores the value of the signal for all the days of the specified interval.

=back

=head2 General exported functions

=over

=item C<< build_object_name($encoded, [ @args ], $key) >>

Generate the name of a signal based on its "encoded" name.

=back

=head2 Functions to manage a repository of signals

  Finance::GeniusTrader::Signals::get_registered_object($name);
  Finance::GeniusTrader::Signals::register_object($name, $object);
  Finance::GeniusTrader::Signals::get_or_register_object($name, $object);
  Finance::GeniusTrader::Signals::manage_object(\@NAMES, $self, $class, $args, $key);

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


# DEFAULT FUNCTIONS FOR SIGNALS
sub new {
    my ($type, $args, $key) = @_;
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

    return manage_object(\@{"$class\::NAMES"}, $self, $class, $self->{'args'}, $key);
}

# Provide a default non-optimized version of detect_interval that
# calls detect once for each day.
#    
# Real signals are encouraged to override this function to provide an
# optimized version of the detection algorithm by possibly reusing
# the result of previous days.
sub detect_interval {
    my ($self, $calc, $first, $last) = @_;

    if (ref($self->{'args'}) =~ /Finance::GeniusTrader::ArgsTree/) {
	$self->{'args'}->prepare_interval($calc, $first, $last);
    }
    for (my $i = $first; $i <= $last; $i++)
    {
	$self->detect($calc, $i);
    }
}

sub initialize { 1; }

1;
