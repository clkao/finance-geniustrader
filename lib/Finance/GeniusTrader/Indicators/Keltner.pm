package Finance::GeniusTrader::Indicators::Keltner;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::ArgsTree;
use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::SMA;
use Finance::GeniusTrader::Indicators::ATR;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("Keltner[#*]", "KeltnerUp[#*]", "KeltnerDown[#*]");
@DEFAULT_ARGS = (9, 2, "{I:Prices HIGH}", "{I:Prices LOW}", "{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::Keltner - Keltner Channel

=head1 DESCRIPTION 


=head2 Parameters

=over

=item Period 1 (default 9)

Period on which the indicator has to be calculated

=item Constant (default 2)

A constant factor with wich the Average True range is multiplied.

=back

=head2 Creation


=head2 Link


=cut


sub initialize {
    my ($self) = @_;

    $self->{'sma'} = Finance::GeniusTrader::Indicators::SMA->new( [ $self->{'args'}->get_arg_names(1),
						    $self->{'args'}->get_arg_names(5) ] );
    $self->{'atr'} = Finance::GeniusTrader::Indicators::ATR->new( [ $self->{'args'}->get_arg_names(1),
						 $self->{'args'}->get_arg_names(3),
						 $self->{'args'}->get_arg_names(4),
						 $self->{'args'}->get_arg_names(5) ] );
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name(0);
    my $lowname = $self->get_name(2);
    my $upname = $self->get_name(1);
    my $nb1 = $self->{'args'}->get_arg_values($calc, $i, 1);

    return if ( !defined($nb1) );

    # Calculate the depencies
    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency( $self->{'sma'}, $nb1 );
    $self->add_volatile_indicator_dependency( $self->{'atr'}, $nb1 );

    return if ( $calc->indicators->is_available($name, $i) &&
		$calc->indicators->is_available($upname, $i) &&
		$calc->indicators->is_available($lowname, $i) );
    return if (! $self->check_dependencies($calc, $i));

    my $mid = $indic->get($self->{'sma'}->get_name, $i);
    my $up = $mid + $indic->get($self->{'atr'}->get_name, $i) * $self->{'args'}->get_arg_values($calc, $i, 2);
    my $low = $mid - $indic->get($self->{'atr'}->get_name, $i) * $self->{'args'}->get_arg_values($calc, $i, 2);

    $indic->set($name, $i, $mid);
    $indic->set($upname, $i, $up);
    $indic->set($lowname, $i, $low);
}

1;
