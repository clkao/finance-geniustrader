package GT::CloseStrategy;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT %OBJECT_REPOSITORY);

require Exporter;
@ISA = qw(Exporter GT::Dependency);
@EXPORT = qw(&build_object_name &manage_object);

use GT::ArgsTree;
use GT::Registry;
use GT::Dependency;
#ALL#  use Log::Log4perl qw(:easy);

=head1 NAME

GT::CloseStrategy - Manages opened positions

=head1 DESCRIPTION

A CloseStrategy is more really a position manager. Once a system has
opened a position, it's managed by a CloseStrategy. Managing means
updating the stop and deciding when to close the position.

=over

=cut

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
	$self->{'args'} = GT::ArgsTree->new(@{$args});
    } elsif (defined (@{"$class\::DEFAULT_ARGS"})) {
	$self->{'args'} = GT::ArgsTree->new(@{"$class\::DEFAULT_ARGS"});
    } else {
	$self->{'args'} = GT::ArgsTree->new(); # no args
    }

    return manage_object(\@{"$class\::NAMES"}, $self, $class, $self->{'args'}, $key);
}

=item C<< $cs->get_indicative_stop($calc, $i, $order, $pf_man, $sys_man) >>

=item C<< $cs->get_indicative_long_stop($calc, $i, $order, $pf_man, $sys_man) >>

=item C<< $cs->get_indicative_short_stop($calc, $i, $order, $pf_man, $sys_man) >>

This function returns an indicative stop level that should be set for the
indicated day. It is used before a position is opened to evaluate
a stop level that may be used by a MoneyManagement rule. 

=item C<< $cs->position_opened($calc, $i, $position, $pf_man, $sys_man) >>

=item C<< $cs->short_position_opened($calc, $i, $position, $pf_man, $sys_man) >>

=item C<< $cs->long_position_opened($calc, $i, $position, $pf_man, $sys_man) >>

Those functions are callback that are launched when a position has been
opened. It can be used to place order on a target that will be valid until
they are executed (ie no_discard=1). $cs->position_opened will
call the right callback depending on the the position (short or long).
It can also be used to set an initial stop level.

=item C<< $cs->manage_position($calc, $i, $position, $pf_man, $sys_man) >>

=item C<< $cs->manage_short_position($calc, $i, $position, $pf_man, $sys_man) >>

=item C<< $cs->manage_long_position($calc, $i, $position, $pf_man, $sys_man) >>

Manage an open position of the corresponding type.  The position may be
augmented or reduced by sending new orders modified by
$manager->set_order_partial(...). The stop may be updated with
$position->set_stop(...).

=cut
sub get_indicative_stop {
    my ($self, $calc, $i, $order, $pf_man, $sys_man) = @_;

    #WAR#  WARN  "position is defined" if ( defined($order));
    
    if ($order->is_buy_order) {
	return $self->get_indicative_long_stop($calc, $i, $order, 
						    $pf_man, $sys_man);
    } else {
	return $self->get_indicative_short_stop($calc, $i, $order, 
						     $pf_man, $sys_man);
    }
}

sub position_opened {
    my ($self, $calc, $i, $position, $pf_man, $sys_man) = @_;
    
    #WAR#  WARN  "position is defined" if ( defined($position));
    #WAR#  WARN  "position quantity is positive" if ( $position->{'quantity'} > 0);
    
    if ($position->is_long) {
	$self->long_position_opened($calc, $i, $position, $pf_man, $sys_man);
    } else {
	$self->short_position_opened($calc, $i, $position, $pf_man, $sys_man);
    }
    return;
}

sub manage_position {
    my ($self, $calc, $i, $position, $pf_man, $sys_man) = @_;
    
    #WAR#  WARN  "position is defined" if ( defined($position));
    #WAR#  WARN  "position quantity is positive" if ( $position->{'quantity'} > 0);
    
    if ($position->is_long) {
	$self->manage_long_position($calc, $i, $position, $pf_man, $sys_man);
    } else {
	$self->manage_short_position($calc, $i, $position, $pf_man, $sys_man);
    }
    return;
}

=item C<< $system->precalculate_all($calc) >>

=item C<< $system->precalculate_interval($calc, $first, $last) >>

If you run a system on a long period of time you may want to precalculate
all the indicators in order to benefit of possible optimizations. This is
the role of those 2 functions.

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
    # This function must be overrident by specific close strategies
    return;
}

# Default functions so that they are not mandatory
sub get_indicative_long_stop	{ return 0; }
sub get_indicative_short_stop	{ return 0; }
sub long_position_opened    { 1; }
sub short_position_opened   { 1; }
sub manage_long_position    { 1; }
sub manage_short_position   { 1; }
sub initialize              { 1; }

=back

=head2 Functions to manage a repository of close strategies

  GT::CloseStrategy::get_registered_object($name);
  GT::CloseStrategy::register_object($name, $object);
  GT::CloseStrategy::get_or_register_object($name, $object);
  GT::CloseStrategy::manage_object(\@NAMES, $object, $class, $args, $key);

=cut
sub get_registered_object {
    GT::Registry::get_registered_object(\%OBJECT_REPOSITORY, @_);
}
sub register_object {
    GT::Registry::register_object(\%OBJECT_REPOSITORY, @_);
}
sub get_or_register_object {
    GT::Registry::get_or_register_object(\%OBJECT_REPOSITORY, @_);
}
sub manage_object {
    GT::Registry::manage_object(\%OBJECT_REPOSITORY, @_);
}

1;
