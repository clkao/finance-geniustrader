package Finance::GeniusTrader::Indicators::Generic::Eval;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Tools qw(:math);
use Math::Trig;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("Eval[#*]");

=head1 NAME

Finance::GeniusTrader::Indicators::Generic::Eval - Evaluate the given expression

=head1 DESCRIPTION

This indicator evaluates the expression given via its argument.
Any indicator is replaced by its current value.

Example of accepted argument list :

=over

=item int({I:RSI})

=item 1+1

=item {I:Generic:SignalLength {Signals:Prices:Advance 5}}+1

=item 100 - {I:RSI 10} * 2

=back

The argument list is treated via perl's eval function so any standard
perl code may be accepted ... but it's only meant for simple single
expression.

=cut
sub initialize {
    my ($self) = @_;

    my $nb = $self->{'args'}->get_nb_args();
    for (my $n = 1; $n <= $nb; $n++) {
	if (! $self->{'args'}->is_constant($n)) {
	    $self->add_arg_dependency($n, 1);
	}
    }

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $nb = $self->{'args'}->get_nb_args();
    my $expr = "";
    for (my $n = 1; $n <= $nb; $n++) {
	if ($self->{'args'}->is_constant($n)) {
	    $expr .= " " . $self->{'args'}->get_arg_constant($n);
	} else {
	    my $val = $self->{'args'}->get_arg_values($calc, $i, $n);
	    return if (! defined($val));
	    $expr .= " $val";
	}
    }
    my $res = undef;
    eval "\$res = $expr";
    if ($@) {
	warn "$@ : $expr";
	return;
    }
    
    $calc->indicators->set($name, $i, $res);
}
