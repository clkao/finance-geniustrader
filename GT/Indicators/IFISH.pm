package GT::Indicators::IFISH;

# Copyright 2008 Karsten Wippler
# Based on and for GeniusTrader (C) 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id: IFISH.pm,v 1.2 2008/03/09 18:06:15 ras Exp ras $

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::ArgsTree;
use GT::Indicators;
use GT::Indicators::EMA;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("IFISH[#1]");
@DEFAULT_ARGS = (9 , 0.1, 50,"{I:RSI 5}" );

=head1 GT::Indicators::IFISH

=head2 Overview
Remember The Fisher Transform
    
                         1 + x
     fisher = 0.5 log ------------
                         1 - x
 Its inverse is

               exp(2*fisher)-1 
     ifisher = ----------------
     	       exp(2*fisher)+1

The input values should lie in the Interval [-5,5]
so they have to be adjusted to this interval.
So an Oscillator is moved,scaled,smoothed and  then inverted.
Ehlers ist using a WMA for the smoothing
I will use an EMA. 

=head2 Paramters

The User has to input valid scaling parameters.
for the RSI they are 0.1 and 50 so
0.1(RSI-50) varies between -5 and 5.
1. smoothing period
2. scaling value
3. midpoint adjustment


=head2 Links
http://mesasoftware.com/technicalpapers.htm

=head2 Creation

 GT::Indicators::IFISH->new()


=cut
sub initialize {

    my ($self) = @_;
    my $scale = "{I:G:Eval ".  $self->{'args'}->get_arg_names(2) ." * (".
   		  $self->{'args'}->get_arg_names(4) ." - " . $self->{'args'}->get_arg_names(3) . ")}";
    $self->{'ema1'} = GT::Indicators::EMA->new([ $self->{'args'}->get_arg_names(1) , $scale ]);



    # Smoothing functions are args 2 and 3
    my $nb_days = $self->{'args'}->get_arg_names(1) + $self->{'args'}->get_arg_names(2);

    $self->add_indicator_dependency($self->{'ema1'},$self->{'args'}->get_arg_names(2));
    $self->add_arg_dependency(5, $nb_days);

    
}

=pod

=head2 GT::Indicators::SMI::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $ema1_name = $self->{'ema1'}->get_name;
    my $name = $self->get_name(0);
    
    return if ($indic->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

       # Return the results
       my $input=$self->{'ema1'}->calculate($calc, $i);
       my $ifish=(exp(2*$input)-1)/(exp(2*$input)+1);
       $indic->set($name, $i, $ifish);

}
1;
