package GT::Indicators::PGO;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Prices;
use GT::Indicators;
use GT::Indicators::SMA;
use GT::Indicators::EMA;
use GT::Indicators::TR;

@ISA = qw(GT::Indicators);
@NAMES = ("PGO[#*]");
@DEFAULT_ARGS = (89, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 GT::Indicators::PGO

=head2 Overview

The Pretty Good Oscillator (PGO) ...

=head2 Calculation

PGO = (Close - N-Day SMA of Close) / N-Day EMA of True Range)

=head2 Parameters

N = 89

=cut

sub initialize {
    my $self = shift;

    my $tr = "{I:TR " . $self->{'args'}->get_arg_names(2) . " " .
      $self->{'args'}->get_arg_names(3) . " " .
	$self->{'args'}->get_arg_names(4) . "}";
    $self->{'ema'} = GT::Indicators::EMA->new([$self->{'args'}->get_arg_names(1),
					       $tr ]);
    $self->{'sma'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names(1),
					        $self->{'args'}->get_arg_names(4) ]);

    $self->add_indicator_dependency($self->{'ema'}, 1);
    $self->add_indicator_dependency($self->{'sma'}, 1);
    $self->add_arg_dependency(4,1);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $name = $self->get_name;
    my $sma_name = $self->{'sma'}->get_name;
    my $ema_name = $self->{'ema'}->get_name;

    return if ($indic->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # Calculate PGO
    my $pgo = (($self->{'args'}->get_arg_values($calc, $i, 4) - 
		$indic->get($sma_name, $i)) / $indic->get($ema_name, $i));
    
    # Return the result
    $indic->set($name, $i, $pgo);
}

1;
