package GT::Indicators::ENV;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::EMA;

@ISA = qw(GT::Indicators);
@NAMES = ("ENVSup[#*]","ENVInf[#*]");
@DEFAULT_ARGS = (25,6,"{I:Prices CLOSE}");

=pod

=head2 GT::Indicators::ENV

An envelope is composed of two moving averages. One moving average is shifted upward and the second moving average is shifted downward.
Envelopes define the upper and the lower boundaries of a security's normal trading range.

The standard envelope (ENV 25-6) can be called like that : GT::Indicators::ENV->new()

If you need a non standard ENV :
GT::Indicators::ENV->new([21, 5])

=cut

sub initialize {
    my $self = shift;

    $self->{'ema'} = GT::Indicators::EMA->new([ $self->{'args'}->get_arg_names(1), 
						$self->{'args'}->get_arg_names(3) ]);

    $self->add_indicator_dependency($self->{'ema'}, 1);
}

=head2 GT::Indicators::ENV::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}[0];
    my $shifted_percentage = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $envsup_name = $self->get_name(0);
    my $envinf_name = $self->get_name(1);
    my $ema = $self->{'ema'};

    return if ($indic->is_available($envsup_name, $i) &&
	       $indic->is_available($envinf_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Get the EMA value
    my $ema_value = $indic->get($ema->get_name, $i);
    
    # Envelope Band Sup is equal to the value of the exponential moving average + fixed percentage deviation
    my $envsup_value = $ema_value * (1 + $shifted_percentage / 100);
    
    # Envelope Band Inf is equal to the value of the exponential moving average - fixed percentage deviation
    my $envinf_value = $ema_value * (1 - $shifted_percentage / 100);
    
    # Return the results
    $indic->set($envsup_name, $i, $envsup_value);
    $indic->set($envinf_name, $i, $envinf_value);
}

1;
