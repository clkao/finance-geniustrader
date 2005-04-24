package GT::Indicators::KirshenbaumBands;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Indicators::EMA;
use GT::Indicators::StandardError;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("KB[#1]","KBSup[#1,#2]","KBInf[#1,#2]");

=head1 GT::Indicators::KirshenbaumBands

=head2 Overview

Kirshenbaum Bands are similar to Bollinger Bands, in that they measure market volatility. However, rather than use Standard Deviation of a moving average for band with, they use Standard Error of linear regression lines of the Close. This has the effect of measuring volatility around the current trend, instead of measuring volatility for changes in trend.

=head2 Author

Paul Kirshenbaum, a money manager and mathematician with PhD in economics
from NYU, submitted this rather unique trading band which is "de-trended".

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args, $key, $func) = @_;
    my $self = { 'args' => defined($args) ? $args : [ 20, 1.75 ] };

    $args->[0] = 20 if (! defined($args->[0]));
    $args->[1] = 1.75 if (! defined($args->[1]));
    
    if (defined($func)) {
	$self->{'_func'} = $func;
    } else {
	$self->{'_func'} = $GET_LAST;
	$key = 'LAST';
    }
						
    return manage_object(\@NAMES, $self, $class, $args, $key);
}

sub initialize {
    my $self = shift;

    $self->{'ema'} = GT::Indicators::EMA->new([ $self->{'args'}[0] ], 
	$self->{'key'}, sub { $self->{'_func'}(@_) });
    $self->{'standard_error'} = GT::Indicators::StandardError->new(
	[ $self->{'args'}[0] ], $self->{'key'}, sub { $self->{'_func'}(@_) });

    $self->add_indicator_dependency($self->{'ema'}, 1);
    $self->add_indicator_dependency($self->{'standard_error'}, 1);
    $self->add_prices_dependency($self->{'args'}[0]);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $ema_name = $self->{'ema'}->get_name;
    my $se_name = $self->{'standard_error'}->get_name;
    my $kb_name = $self->get_name(0);
    my $kbsup_name = $self->get_name(1);
    my $kbinf_name = $self->get_name(2);
    my $n = $self->{'args'}[1];

    return if ($indic->is_available($kb_name, $i) &&
	       $indic->is_available($kbsup_name, $i) &&
	       $indic->is_available($kbinf_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Calculate and get the P-Period EMA value
    my $ema_value = $indic->get($ema_name, $i);

    # Calculate and get Standard Error value
    my $se_value = $indic->get($se_name, $i);
    
    # Kirshenbaum Band Sup is equal to the value of the exponential moving
    # average + standard error
    my $kbsup_value = $ema_value + ($n * $se_value);
    
    # Kirshenbaum Band Inf is equal to the value of the exponential moving
    # average - standard error
    my $kbinf_value = $ema_value - ($n * $se_value);
    
    # Return the results
    $indic->set($kb_name, $i, $ema_value);
    $indic->set($kbsup_name, $i, $kbsup_value);
    $indic->set($kbinf_name, $i, $kbinf_value);
}

1;
