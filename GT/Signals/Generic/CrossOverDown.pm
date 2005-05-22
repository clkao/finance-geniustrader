package GT::Signals::Generic::CrossOverDown;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Eval;
use GT::Tools qw(:generic);

@ISA = qw(GT::Signals);
@NAMES = ("CrossOverDown[#*]");

=head1 CrossOver Generic Signal

=head2 Overview

This Generic Signal will be able to tell you when a specific indicator is
crossing down an other one.

=head2 EXAMPLE

You can check test if the closing price has crossed
under the 14 day EMA, with this signal:

  S:Generic:CrossOverDown {I:Prices CLOSE} {I:EMA 14}

=cut
sub initialize {
    my ($self) = @_;
    warn "Bad number of arguments given to S:Generic:CrossOverDown !" if ($self->{'args'}->get_nb_args() != 2);
    $self->add_arg_dependency(1, 1) unless $self->{'args'}->is_constant(1);
    $self->add_arg_dependency(2, 1) unless $self->{'args'}->is_constant(2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    
    return if (! $self->check_dependencies($calc, $i));
    return if ($calc->signals->is_available($self->get_name, $i));

    my $first1 =  $self->{'args'}->get_arg_values($calc, $i - 1, 1);
    my $first2 =  $self->{'args'}->get_arg_values($calc, $i, 1);
    my $second1 =  $self->{'args'}->get_arg_values($calc, $i - 1, 2);
    my $second2 =  $self->{'args'}->get_arg_values($calc, $i, 2);
    
    return if (not (defined($first1) && defined($first2) && defined($second1) && defined($second2)));
    
    if (($first1 >= $second1) and ($first2 < $second2)) {
	$calc->signals->set($self->get_name, $i, 1);
    } else {
	$calc->signals->set($self->get_name, $i, 0);
    }
}

1;
