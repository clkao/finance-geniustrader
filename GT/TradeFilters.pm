package GT::TradeFilters;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT %OBJECT_REPOSITORY);

require Exporter;
@ISA = qw(Exporter GT::Dependency);
@EXPORT = qw(&build_object_name &manage_object);

use GT::Registry;
use GT::Dependency;
#ALL#  use Log::Log4perl qw(:easy);

=head1 NAME

GT::TradeFilters - Filters to accept or refuse trades

=head1 DESCRIPTION

Trade filters are used to decide whether or not a trade is accepted.
It can for example refuse trade going against the current trend.
You can use several trade filters simultaneously.

=over

=item C<< $filter->accept_trade($order, $i, $calc, $portfolio) >>

=cut
sub accept_trade {
    my ($self, $order, $i, $calc, $portfolio) = @_;
    
    # Automatically accept
    return 1;
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
    # This function must be overrident by specific trade filters
    return;
}


# Default initialize that does nothing
sub initialize { 1 }

# GT::Registry functions
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


=back

=cut
1;
