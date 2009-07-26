package Finance::GeniusTrader::Indicators::BPCorrelation;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber, Oliver Bossert
# standards upgrade Copyright 2005 Thomas Weigert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# includes ras hack to protect against division by zero
# detection of missing or invalid arguments
# $Id$

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Indicators;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("BPCorrelation[#1,#2,#3]");

=head2 Finance::GeniusTrader::Indicators::BPCorrelation (Bravais-Pearson Correlation Coefficient)

This function will calculate the Bravais-Pearson Correlation Coefficient.
Correlation analysis measures the relationship between two items and shows
if changes in one item will result in changes in the other item.

this indicator requires three arguments, and provides no default values
for any of them.

the first argument is the number of intervals in the period,
it can be a constant or a data series. the period is used as
the number of data values used in each computation

the second and third arguments must be functions (e.g. data series
or data objects?)

the indicator will validate that the arguments are provided and are
of the correct type.

=head2 examples (display_indicator)
 
 %   display_indicator.pl I:BPCorrelation 13000 \
 '20 {I:Prices OPEN} {I:Prices CLOSE}'

 %   display_indicator.pl I:BPCorrelation 13000 \
 '14 {I:G:Cum 1} {I:Prices CLOSE}'
 

=cut
sub initialize {
    my ($self) = @_;

    if ($self->{'args'}->is_constant(1)) {
        $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
    } else {
    $self->add_prices_dependency(20);
}

    # indicator requires 3 arguments
    my $err = 0;
    ( my $msg_n = $NAMES[0] ) =~ s/^(.*)\[.*/$1/;
    my $msg = "$msg_n: argument error\n";
    if ( ! defined($self->{'args'}[1]) ) {
    $msg .= join "", "\targ #1 must not be null\n";
      ++$err;
    }
    # indicator requires functions for 2nd and 3rd arguments
    # skip self and first
    for ( my $i = 2; $i <= 3; ++$i ) {
      if ( ! defined($self->{'args'}[$i])
       ||  $self->{'args'}->is_constant($i)) {
        my $msg_txt = "must be a function (series)\n";
        $msg .= join "", "\targ #$i \"$self->{'args'}[$i]\" $msg_txt";
        ++$err;
      }
    }
    die "$msg" if ( $err );
}

=head2 Finance::GeniusTrader::Indicators::Correlation::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;
    my $period = $self->{'args'}->get_arg_constant(1);
    my $average_x = 0;
    my $average_y = 0;
    my $sum_y = 0;
    my $sum_x = 0;
    my $sum_xy = 0;
    
    return if ($calc->indicators->is_available($name, $i));

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2, $period);
    $self->add_volatile_arg_dependency(3, $period);

    return if (! $self->check_dependencies($calc, $i));
    return if (defined($period) && ($i + 1 < $period));

    if (!defined $period) {
	$period = $i;
    }
    
    for(my $n = $i - $period + 1; $n <= $i; $n++) {

        $average_x += $self->{'args'}->get_arg_values($calc, $n, 2);
        $average_y += $self->{'args'}->get_arg_values($calc, $n, 3);
    }
    
    $average_x /= $period;
    $average_y /= $period;
    
    for(my $n = $i - $period + 1; $n <= $i; $n++) {
        $sum_x += ($self->{'args'}->get_arg_values($calc, $n, 2) - $average_x) ** 2;    
        $sum_y += ($self->{'args'}->get_arg_values($calc, $n, 3) - $average_y) ** 2;    
        $sum_xy += ($self->{'args'}->get_arg_values($calc, $n, 2) - $average_x)
          * ($self->{'args'}->get_arg_values($calc, $n, 3) - $average_y);
    }

    # Calculate the Bravais-Pearson Correlation Coefficient
    # protect against division by zero
    my $den = ($sum_x * $sum_y) ** 0.5 || 0.0000001;
    my $correlation = $sum_xy / $den;
    
    # Return the result
    $calc->indicators->set($name, $i, $correlation);
}

1;
