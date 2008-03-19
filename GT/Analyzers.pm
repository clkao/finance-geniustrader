package GT::Analyzers;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA  %OBJECT_REPOSITORY);

require Exporter;
@ISA = qw(Exporter GT::Dependency);

use GT::Prices;
use GT::Calculator;
use GT::Registry;
use GT::Dependency;
use GT::Portfolio;
use GT::Portfolio::Order;
use GT::Conf;
use GT::Eval;
use GT::DateTime;
use GT::ArgsTree;

=head1 NAME

GT::Analyzers - Provides some functions that will be used by all analyzer modules.

=head1 DESCRIPTION


=head2 MANAGE A REPOSITORY OF INDICATORS

  GT::Analyzers::get_registered_object($name);
  GT::Analyzers::register_object($name, $object);
  GT::Analyzers::get_or_register_object($name, $object);
  GT::Analyzers::manage_object(\@NAMES, $object, $class, $args, $key);

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


=head2 DEFAULT FUNCTIONS FOR ANALYZERS

=over 

=item C<< GT::Analyzers::Module->new($args, $key, $func) >>

Create a new analyzer with the given arguments. $key and $func are optional,
they are useful for indicators which can use non-usual input streams.

=cut
sub new {
    my ($type, $args, $key, $func) = @_;
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

    if (defined($func)) {
	$self->{'func'} = $func;
    }

    return manage_object(\@{"$class\::NAMES"}, $self, $class, $self->{'args'}, $key);
}




=item C<< $analyzers->initialize() >>

Default method that does nothing.

=back

=cut

sub initialize { 1; }

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    if (ref($self->{'args'}) =~ /GT::ArgsTree/) {
	$self->{'args'}->prepare_interval($calc, $first, $last);
    }
    for (my $i = $first; $i <= $last; $i++)
    {
	$self->calculate($calc, $i);
    }
}


1;
