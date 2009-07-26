package GT::Indicators::SMA;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

# $Id$

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("SMA[#*]");
@DEFAULT_ARGS = (50, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::SMA - Simple Moving Average

=head1 DESCRIPTION 

A simple arithmetic moving average.

=head2 Parameters

=over

=item Period (default 50)

The first argument is the period used to calculed the average.

=item Other data input

The second argument is optional. It can be used to specify an other
stream of input data for the average instead of the close prices.
This is usually an indicator (detailed via {I:MyIndic| <param>}) but
it can also be "{I:Prices OPEN}", "{I:Prices HIGH}", "{I:Prices LOW}",
"{I:Prices CLOSE}", "{I:Prices FIRST}" and "{I:Prices LAST}" and in
which cases the corresponding prices serie will be used.

=back

=head2 Creation

 GT::Indicators::SMA->new()
 GT::Indicators::SMA->new([20])

If you need a 30 days SMA of the opening prices you can write
the following line:

 GT::Indicators::SMA->new([30, "{I:Prices OPEN}"])

A 10 days SMA of the RSI could be created with :

 GT::Indicators::SMA->new([10, "{I:RSI}"])

=cut

sub initialize {
    my ($self) = @_;
    if ($self->{'args'}->is_constant(1) && ($self->{'args'}->get_nb_args() > 1)) {
	$self->add_arg_dependency(2, $self->{'args'}->get_arg_constant(1));
    }
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;
    my $sum = 0;

    return if $calc->indicators->is_available($name, $i);

    return if (! defined($nb) || $nb==0);

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $nb);

    return if (! $self->check_dependencies($calc, $i));
    
    for(my $n = $i - $nb + 1; $n <= $i; $n++) 
    {
	my $val = $self->{'args'}->get_arg_values($calc, $n, 2);
	return if (! defined($val));
	$sum += $val;
    }
    $calc->indicators()->set($name, $i, $sum / $nb);
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $name = $self->get_name;

    ($first, $last) = $self->update_interval($calc, $first, $last);
    return if ($calc->indicators->is_available_interval($name, $first, $last));
    return if (! $self->check_dependencies_interval($calc, $first, $last));
    
    if ($self->{'args'}->is_constant(1)) {
	my $nb = $self->{'args'}->get_arg_constant(1);
	my $sum = 0;
	# Calculate the new SMA value from the previous one when possible
	for(my $i = $first - $nb + 1; $i <= $last; $i++)
	{
	    my $val = $self->{'args'}->get_arg_values($calc, $i, 2);
	    next if (! defined($val));
	    if ($i <= $first) {
		$sum += $val;
		if ($i == $first) {
		    $calc->indicators->set($name, $i, $sum / $nb);
		}
	    } else {
		$sum += $val - $self->{'args'}->get_arg_values($calc, $i - $nb, 2);
		$calc->indicators->set($name, $i, $sum / $nb);
	    }
	}
    } else {
	# Calculate for each day separately
	GT::Indicators::calculate_interval(@_);
    }
}

1;
