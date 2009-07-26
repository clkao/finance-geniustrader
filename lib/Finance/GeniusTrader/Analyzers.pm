package Finance::GeniusTrader::Analyzers;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA  %OBJECT_REPOSITORY);

require Exporter;
@ISA = qw(Exporter Finance::GeniusTrader::Dependency);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Calculator;
use Finance::GeniusTrader::Registry;
use Finance::GeniusTrader::Dependency;
use Finance::GeniusTrader::Portfolio;
use Finance::GeniusTrader::Portfolio::Order;
use Finance::GeniusTrader::Conf;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::DateTime;
use Finance::GeniusTrader::ArgsTree;

=head1 NAME

Finance::GeniusTrader::Analyzers - Provides some functions that will be used by all analyzer modules.

=head1 DESCRIPTION


=head2 MANAGE A REPOSITORY OF INDICATORS

  Finance::GeniusTrader::Analyzers::get_registered_object($name);
  Finance::GeniusTrader::Analyzers::register_object($name, $object);
  Finance::GeniusTrader::Analyzers::get_or_register_object($name, $object);
  Finance::GeniusTrader::Analyzers::manage_object(\@NAMES, $object, $class, $args, $key);

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


=head2 DEFAULT FUNCTIONS FOR ANALYZERS

=over 

=item C<< Finance::GeniusTrader::Analyzers::Module->new($args, $key, $func) >>

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
	$self->{'args'} = Finance::GeniusTrader::ArgsTree->new(@{$args});
    } elsif (defined (@{"$class\::DEFAULT_ARGS"})) {
	$self->{'args'} = Finance::GeniusTrader::ArgsTree->new(@{"$class\::DEFAULT_ARGS"});
    } else {
	$self->{'args'} = Finance::GeniusTrader::ArgsTree->new(); # no args
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

    if (ref($self->{'args'}) =~ /Finance::GeniusTrader::ArgsTree/) {
	$self->{'args'}->prepare_interval($calc, $first, $last);
    }
    for (my $i = $first; $i <= $last; $i++)
    {
	$self->calculate($calc, $i);
    }
}


1;
