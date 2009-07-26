package GT::Indicators::Generic::Min;

# Copyright 2000-2002 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);

@ISA = qw(GT::Indicators);
@NAMES = ("Min[#*]");

=head1 NAME

GT::Indicators::Generic::Min - Return the minimum of all parameters

=head1 DESCRIPTION

This indicator returns the smallest value of all its parameters.

=cut
sub initialize {
    my ($self) = @_;

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    
    return if ($calc->indicators->is_available($name, $i));

    my $res = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $expr = "";
    for (my $n = 2; $n <= $self->{'args'}->get_nb_args(); $n++) {
	my $val = $self->{'args'}->get_arg_values($calc, $i, $n);
	if (defined($val)) {
	    $res = min($res, $val);
	}
    }
    
    if (defined($res)) {
	$calc->indicators->set($name, $i, $res);
    }
}
