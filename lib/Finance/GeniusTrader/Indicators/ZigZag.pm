package GT::Indicators::ZigZag;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("ZigZag[#*]");
@DEFAULT_ARGS = (10, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::ZigZag

=head1 DESCRIPTION 

The Zig Zag indicator filters out changes in an underlying plot (e.g., a security's price or another indicator) that are less than a specified amount. The Zig Zag indicator only shows significant changes.

=head2 Parameters

=over 

=item Percentage change (10%)

The first argument is the percentage change required to yield a line that only reverses after a change from high to low of 10% or greater.

=back

=head2 Creation

 GT::Indicators::ZigZag->new()
 GT::Indicators::ZigZag->new([5])

If you need an 8 % ZigZag indicator of the opening prices you can write
one of those lines :

 GT::Indicators::SMA->new([8], "OPEN", $GET_OPEN)
 GT::Indicators::SMA->new([8, "OPEN"])

A ZigZag indicator with a 20 % threshold of the Volume could be created with :

 GT::Indicators::ZigZag->new([20, "{I:Volume}"])

=cut

sub initialize {
    my ($self) = @_;
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $percentage = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;

    return if (! defined($percentage));

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $percentage);
    return if (! $self->check_dependencies($calc, $i));

    my $previous_peak = 0;
    my $zigzag = 0;
    my $date = 0;
    my $sign = 0;

    for (my $n = 0; $n <= $i; $n++) {
	
	if ($self->{'args'}->get_arg_values($calc, $n, 2) >= $previous_peak * (1 + $percentage / 100)) {
	    if ($sign eq -1) {
		$calc->indicators()->set($name, $date, $previous_peak);
	    }
	    $date = $n;
	    $sign = 1;
	}
	if ($self->{'args'}->get_arg_values($calc, $n, 2) <= $previous_peak * (1 - $percentage / 100)) {
	    if ($sign eq 1) {
		$calc->indicators()->set($name, $date, $previous_peak);
	    }
	    $date = $n;
	    $sign = -1;
	}
	if (($sign eq 1) and ($self->{'args'}->get_arg_values($calc, $n, 2) > $previous_peak)) {
	    $previous_peak = $self->{'args'}->get_arg_values($calc, $n, 2);
	    $date = $n;
	}
	if (($sign eq -1) and ($self->{'args'}->get_arg_values($calc, $n, 2) < $previous_peak)) {
	    $previous_peak = $self->{'args'}->get_arg_values($calc, $n, 2);
	    $date = $n;
	}
    }
    $calc->indicators()->set($name, $i, $previous_peak);
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    $self->calculate($calc, $last);
}

1;
