package GT::Indicators::Interquartil;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("IQ[#*]");
@DEFAULT_ARGS = (50, 80, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::Interqurtil - Interquartil-Distance

=head1 DESCRIPTION 

The Interquartil-distance; which is the position at which you can
divide the data by x% on the left side and (100-x)% on the right side.

=head2 Parameters

=over 

=item Percentage

Percentage of the IQD (median = 50%)

=item Period (default 50)

The first argument is the period used to calculed the average.

=item Other data input

The Data for the calculation.

=back

=head2 Creation

To create a kind of dynamic borders for the RSI try:

Indicators::Interquartil(90,50,{I:RSI})
Indicators::Interquartil(10,50,{I:RSI})

 
=cut
sub initialize {
    my ($self) = @_;
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $getvalue = $self->{'func'};
    my $name = $self->get_name;

    return if (! defined($nb));

    $self->remove_volatile_dependencies();
    $self->add_volatile_prices_dependency($nb);

    return if (! $self->check_dependencies($calc, $i));

    my @values = ();
    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	my $val = &$getvalue($calc, $n);
	return if (! defined($val));
	push @values, $val;
    }
    @values = sort { $a <=> $b } @values;
    my $pos = int( $self->{'args'}->get_arg_values($calc, $i, 1) * ($#values) / 100 );
    $pos = 0 if ($pos < 0);
    $pos = $#values if ($pos > $#values);
    my $erg = $values[$pos];

    $calc->indicators()->set($name, $i, $erg);
}

1;
