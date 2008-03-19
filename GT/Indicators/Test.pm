package GT::Indicators::Test;

# Copyright 2008 Thomas Weigert
# Based on and for GeniusTrader (C) 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# initial version 29 feb 08
# $Id: Test.pm,v 1.1 2008/03/01 04:08:16 ras Exp ras $

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("Test[#1,#2,#3,#4]","CM[#1]");
@DEFAULT_ARGS = (5, 3, 3, "EMA", "Generic::MinInPeriod", "{I:Prices CLOSE}" );

=head1 NAME

GT::Indicators::Test - Indicator to test embedding of indicators

=head1 DESCRIPTION

This indicator functions as a test rig to ensure that another indicator
is robust in the presence of complex embedding into other indicators.

It is not generic, unfortunately, but tests indicators only with respect
to their first argument.

Use it as follows:

 ./display_indicator.pl --start=2000-06-16 --end=2000-06-29 \
 I:Test 13000 60 60 60 SMA Generic::MaxInPeriod

This will test the SMA; the second indicator Generic::MaxInPeriod is only
there to add complexity. It defaults to Generic::MinInPeriod.

This test will do the following: 

1. Apply Arg5 to Arg6, using Arg1 as parameter (by default:
    {I:Generic:MinInPeriod 5 {I:Prices CLOSE}}
2. Smooth the result by Arg4, using Arg2 as parameter (by default:
    {I:EMA 3 ...}
3. Smooth the result by Arg4, using Arg3 as parameter (by default:
    {I:EMA 3 ...}

The first output is the result (3), the second output is the result (1).

=cut


sub initialize {
    my $self = shift;

    my $ind1 = $self->{'args'}->get_arg_names(4);
    my $ind2 = $self->{'args'}->get_arg_names(5);
    eval "use GT::Indicators::$ind1;\n";
    eval "use GT::Indicators::$ind2;\n";
    
    # We need to call MIN and MAX first
    my $min = "\$self->{'min'} = GT::Indicators::$ind2->new([ \$self->{'args'}->get_arg_names(1), \$self->{'args'}->get_arg_names(6)  ]);";
    eval $min;


    # Initialize smoothing of CM
    my $smoothing = "\$self->{'smooth_cm'} = GT::Indicators::$ind1->new([ \$self->{'args'}->get_arg_names(3), \"{I:$ind1 \" . \$self->{'args'}->get_arg_names(2) . \"{I:Generic:ByName \" . \$self->get_name(1) . \"}}\" ])";
    eval $smoothing;


    # Smoothing functions are args 2 and 3
    my $nb_days = $self->{'args'}->get_arg_names(2)+$self->{'args'}->get_arg_names(3);

    $self->add_indicator_dependency($self->{'min'}, $nb_days+1);
    $self->add_arg_dependency(6, $nb_days + $self->{'args'}->get_arg_constant(1));

    
}

=pod

=head2 GT::Indicators::Test::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $min_name = $self->{'min'}->get_name;
    my $name = $self->get_name(0);
    my $cm_name = $self->get_name(1);
    
    return if ($indic->is_available($cm_name, $i) &&
	       $indic->is_available($name, $i));


    # Smoothing functions are args 2
    my $nb_days = $self->{'args'}->get_arg_values($calc, $i, 2)+$self->{'args'}->get_arg_values($calc, $i, 3);

    return if (! $self->check_dependencies($calc, $i));

    # Calculate CM
    for (my $n = 0; $n < $nb_days; $n++) {

	# Return if CM is available
	next if $indic->is_available($cm_name, $i - $n);
	
	# Get MIN and MAX
	my $lowest_low = $indic->get($min_name, $i - $n);
    
        # Calculate CM
        my $cm_value = $lowest_low;

	# Return the results
	$indic->set($cm_name, $i - $n, $cm_value);

    }


    $self->{'smooth_cm'}->calculate($calc, $i);
    my $s2 = $indic->get($self->{'smooth_cm'}->get_name, $i);
    $indic->set($name, $i, $s2);
    

}


1;
