package GT::Indicators::TMA;

# Copyright 2000-2002 Rapha�l Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("TMA[#1]");

=head1 GT::Indicators::TMA

=head2 Overview

Triangular Moving Averages (TMA) place the majority of the weight on the middle portion of the price series.

=head2 Calculation

TMA(5) = (1/9) * (1 * Close(i) + 2 * Close(i - 1) + 3 * Close(i - 2) + 2 * Close(i - 3) + 1 * Close(i - 4))

=head2 Examples

GT::Indicators::TMA->new()
GT::Indicators::TMA->new([50])
GT::Indicators::TMA->new([30], "OPEN", $GET_OPEN)

=head2 Links

http://www.equis.com/free/taaz/movingaverages.html
http://www.ivorix.com/en/products/tech/smooth/tma.html

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

=head2 GT::Indicators::TMA::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}[0];
    my $getvalue = $self->{'_func'};
    my $name = $self->get_name;
    my $weight = 0;
    my $sum_of_weight = 0;
    my $sum = 0;
    my $up = 1;
    my $first = 0;
    
    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $max_weight = int(($nb / 2) + 0.99);
    
    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	# Determine the weights
	if ($up eq 1) {
	    if ($weight < $max_weight) {
		$weight += 1;
	    }
	    if (($weight eq $max_weight) and (($nb / 2) != $max_weight)) {
		$up = 0;
	    }
	    if (($weight eq $max_weight) and (($nb / 2) eq $max_weight)) {
		if ($first != 0) {
		    $up = 0;
		} else {
		    $first = 1;
		}
	    }
	} else {
	    $weight -= 1;
	}
	$sum += &$getvalue($calc, $n) * $weight;
	$sum_of_weight += $weight;
    }
    $calc->indicators->set($name, $i, $sum / $sum_of_weight);
}

1;
