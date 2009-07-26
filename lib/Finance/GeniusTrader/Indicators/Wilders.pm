package Finance::GeniusTrader::Indicators::Wilders;

# Copyright 2005 Thomas Weigert
# Based on and for GeniusTrader (C) 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id: Wilders.pm,v 1.4 2009/07/09 16:28:46 ras Exp ras $

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::SMA;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("Wilders[#*]");
@DEFAULT_ARGS = (14, "{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::Wilders - Wilder's smoothing (aka wells wilders moving average)

=head1 DESCRIPTION 

Wilder's smoothing is using simple averages for the initial calculation. 
For the subsequent average calculations, he drops 1/14th of the previous 
average value and adds 1/nth of the new value. This is the "classic" 
exponential average, in which the smoothing factor is 1/n, instead of the 
"modern" exponential average, in which the smoothing factor is 2/(n+1).

Wilders(i) = (1/n) * Close(i) + (1 - 1/n) * Wilders(i-1)


=head2 Parameters

=over

=item Period (default 14)

The first argument is the period used to calculed the average.

=item Other data input

The second argument is optional. It can be used to specify an other
stream of input data for the average instead of the close prices.
This is usually an indicator, including I:Prices.

=back

=head2 Creation

 Finance::GeniusTrader::Indicators::Wilders->new()
 Finance::GeniusTrader::Indicators::Wilders->new([20])

If you need a 30 days Wilders of the opening prices you can write
the following line:

 Finance::GeniusTrader::Indicators::Wilders->new([30, "{I:Prices OPEN}"])

A 10 days Wilders of the RSI could be created with :

 Finance::GeniusTrader::Indicators::Wilders->new([10, "{I:RSI}"])

=cut

sub initialize {
    my ($self) = @_;

    unless ( $self->{'args'}->is_constant(1) ) {
      print STDERR __PACKAGE__ . ": error: Argument 1 \""
       . $self->{'args'}->get_arg_names(1)
       . "\" must be a constant value.";
      die "\n";
    } 

    $self->{'sma'} = Finance::GeniusTrader::Indicators::SMA->new([ $self->{'args'}->get_arg_names() ]);
    $self->add_indicator_dependency($self->{'sma'}, 1);
    $self->add_arg_dependency(2, $self->{'args'}->get_arg_names(1));
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name;
    my $before = 1;

    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    return if (! defined($nb) || $nb==0);

    return if ($indic->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $prev = $indic->get($name, $i - 1);
    my $k = 1 / $nb;
    my $wilders;
    if (defined $prev) {
      $wilders = $prev * (1 - $k) + $self->{'args'}->get_arg_values($calc, $i, 2) * $k;
    } else {
      $wilders = $indic->get($self->{'sma'}->get_name, $i);
      $before = 0;
    }
    $indic->set($name, $i, $wilders);
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name;

    my $nb = $self->{'args'}->get_arg_constant(1);
    return if (! defined($nb) || $nb==0);

    return if ($indic->is_available_interval($name, $first, $last));
    # Don't need to calculate all SMA values, just the first data point.
    $self->{'sma'}->calculate($calc, $first);

    return unless $self->dependencies_are_available($calc, $first);

    my $k = 1 / $nb;

    $indic->set($name, $first, $indic->get($self->{'sma'}->get_name, $first));

    for (my $i=$first+1;$i<=$last;$i++) {
      my $prev = $indic->get($name, $i - 1);
      my $wilders = $prev * (1 - $k) + $self->{'args'}->get_arg_values($calc, $i, 2) * $k;
      $indic->set($name, $i, $wilders);
    }
}

1;
