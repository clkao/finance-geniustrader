package Finance::GeniusTrader::Indicators;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @EXPORT $GET_FIRST $GET_OPEN $GET_HIGH $GET_LOW $GET_LAST
	    $GET_CLOSE $GET_VOLUME %OBJECT_REPOSITORY);

require Exporter;
@ISA = qw(Exporter Finance::GeniusTrader::Dependency);
@EXPORT = qw($GET_FIRST $GET_OPEN $GET_HIGH $GET_LOW $GET_LAST $GET_CLOSE
	     $GET_VOLUME &build_object_name &manage_object);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Calculator;
use Finance::GeniusTrader::Registry;
use Finance::GeniusTrader::Dependency;
use Finance::GeniusTrader::ArgsTree;
#ALL#  use Log::Log4perl qw(:easy);

=head1 NAME

Finance::GeniusTrader::Indicators - Provides some functions that will be used by all indicators.

=head1 DESCRIPTION

=head2 GENERIC EXPORTED FUNCTIONS

=over

=item C<< build_object_name($encoded, [ @args ], $key) >>

Generate the name of an indicator based on its "encoded" name.

=back

=head2 FUNCTIONS TO RETRIEVE USUAL PRICES

$GET_OPEN, $GET_FIRST, $GET_HIGH, $GET_LOW, $GET_LAST, $GET_CLOSE
and $GET_VOLUME are functions references that can be passed as arguments
to some indicators where input functions are expected. They are
automatically exported when doing "use Finance::GeniusTrader::Indicators;".

For example, the indicator AMA (Arithmetic Moving Average) can be used
to calculate the average of anything (other indicators or prices). You
can provide those functions if you want to calculate an average of
some prices (or quotations or volumes).

=cut
$GET_FIRST  = $GET_OPEN  = sub { $_[0]->prices()->at($_[1])->[$FIRST] };
$GET_HIGH   =              sub { $_[0]->prices()->at($_[1])->[$HIGH] };
$GET_LOW    =              sub { $_[0]->prices()->at($_[1])->[$LOW] };
$GET_LAST   = $GET_CLOSE = sub { $_[0]->prices()->at($_[1])->[$LAST] };
$GET_VOLUME =              sub { $_[0]->prices()->at($_[1])->[$VOLUME] };

=head2 MANAGE A REPOSITORY OF INDICATORS

  Finance::GeniusTrader::Indicators::get_registered_object($name);
  Finance::GeniusTrader::Indicators::register_object($name, $object);
  Finance::GeniusTrader::Indicators::get_or_register_object($name, $object);
  Finance::GeniusTrader::Indicators::manage_object(\@NAMES, $object, $class, $args, $key);

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

=head2 DEFAULT FUNCTIONS FOR INDICATORS

=over 

=item C<< Finance::GeniusTrader::Indicators::Module->new($args, $key, $func) >>

Create a new indicator with the given arguments. $key and $func are optional,
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
	# User supplied input
	#$self->{'func'} = $func;
	die "We tried to pass a 'func' parameter to an indicator, please convert the module...";
    } #else {
	# We make the supposition that the last parameter is going to be
	# an input parameter ...
	#$self->{'func'} = sub { $self->{'args'}->get_arg_values($_[0], $_[1],
	#							$self->{'args'}->get_nb_args() ); };
    #}
    $self->{'func'} = sub { die "Please convert this module to NOT use \$self->{'func'} ..."; };
    
    return manage_object(\@{"$class\::NAMES"}, $self, $class, $self->{'args'}, $key);
}

=item C<< $indic->calculate_all($calc) >>

calculate_all will calculate all the values of the indicators for all
possibles days.

=cut
sub calculate_all {
    my ($self, $calc) = @_;
    my $c = $calc->prices->count;
    my $indic = $calc->indicators;

    $self->calculate_interval($calc, 0, $c - 1);
    return;
}

=item C<< $indic->calculate_interval($calc, $first, $last) >>

Provide a default non-optimized version of calculate_interval that
calls calculate once for each day.

Real indicators are encouraged to override this function to provide an
optimized version of the calculation algorithm by possibly reusing
the result of previous days.

=cut
sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    if (ref($self->{'args'}) =~ /Finance::GeniusTrader::ArgsTree/) {
	$self->{'args'}->prepare_interval($calc, $first, $last);
    }
    for (my $i = $first; $i <= $last; $i++)
    {
	$self->calculate($calc, $i);
    }
    return;
}

=item C<< $indic->initialize() >>

Default method that does nothing.

=cut
sub initialize { 1; }

=item C<< $indic->get_name >>

=item C<< $indic->get_name($n) >>

Get the name of the indicator. If the indicator returns several values,
you can get the name corresponding to any value, you just have to
precise in the parameters the index of the value that you're interested
in.

=item C<< $indic->get_nb_values >>

Return the number of different values produced by this indicator that are
available for use.

=back

=cut
# Those functions are exported by Finance::GeniusTrader::Registry

1;
