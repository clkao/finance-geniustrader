package GT::OrderFactory;

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

GT::OrderFactory - Create orders

An OrderFactory is used to create an order when a system has detected an
opportunity. This order will then be sent to the PortfolioManager by
the SystemManager.

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

=over

=item C<< $of->create_buy_order($calc, $i, $sys_manager, $pf_manager) >>

=item C<< $of->create_sell_order($calc, $i, $sys_manager, $pf_manager) >>

Those functions are called by the systems to launch an order. The
SystemManager delegates this to an Order object. It will
use the Order object given by set_default_order() or it will
fallback to the order suggested by the system.

=cut
sub create_buy_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

    return;
}

sub create_sell_order {
    my ($self, $calc, $i, $sys_manager, $pf_manager) = @_;

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

=pod

=back

=cut
1;
