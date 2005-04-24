package GT::Indicators::EPMA;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("EPMA[#1]");

=head2 GT::Indicators::EPMA

=head2 Overview

The Endpoint Moving Average (EPMA) is focus on divergences between the original time series and the transposed time series. They may be used in
forecasting applications or as additional inputs for neural analyses.

=head2 Calculation

EPMA(n) = [2 / (n * (n + 1))] * Sum of (((3 * i) - n - 1) * Close(i)) from i = 1 to i = n

=head2 Examples

GT::Indicators::EPMA->new()
GT::Indicators::EPMA->new([50])
GT::Indicators::EPMA->new([30], "OPEN", $GET_OPEN)

=head2 Links

http://www.ivorix.com/en/products/tech/smooth/epma.html

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args, $key, $func) = @_;
    my $self = { 'args' => defined($args) ? $args : [ 20 ] };
    
    # User defined function to get data or default with close prices
    if (defined($func)) {
	$self->{'_func'} = $func;
    } else {
	$self->{'_func'} = $GET_LAST;
	$key = 'LAST';
    }

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, $key);
}

sub initialize {
    my ($self) = @_;

    $self->add_prices_dependency($self->{'args'}[0]);
}
=head2 GT::Indicators::EPMA::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}[0];
    my $getvalue = $self->{'_func'};
    my $name = $self->get_name;
    my $weight = 0;
    my $sum = 0;
    my $position = 0;
    
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	$position += 1;
	$weight = ((3 * $position) - $nb - 1) ;
	$sum += &$getvalue($calc, $n) * $weight;
    }
    my $coef = ( 2 / ($nb * ($nb + 1)));
    $calc->indicators->set($name, $i, $sum * $coef);
}

1;
