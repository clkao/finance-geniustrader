package GT::Indicators::RAVI;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::ArgsTree;
use GT::Indicators;
use GT::Indicators::SMA;

@ISA = qw(GT::Indicators);
@NAMES = ("RAVI[#*]");
@DEFAULT_ARGS = (7, 65, "{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::RAVI - RAVI Trendindicator

=head1 DESCRIPTION 

The RAVI is a simple yet efficient trendindicator. It is calculated as
follows:

RAVI = ABS ( 100 * ( SMA(Short) - SMA(Long) ) / SMA(Long) )

The long Period divided by the short should always be 10.
A Trend is indicated if the RAVI crosses the 3%-level.


=head2 Parameters

=over

=item Short Period (default 7)

The first argument is the period used to calculed the short average.

=item Long Period (default 65)

The second argument is the period used to calculed the long average.

=back

=cut


sub initialize {
    my ($self) = @_;

    $self->{'sma1'} = GT::Indicators::SMA->new( [ $self->{'args'}->get_arg_names(1),
						  $self->{'args'}->get_arg_names(3) ] );
    $self->{'sma2'} = GT::Indicators::SMA->new( [ $self->{'args'}->get_arg_names(2),
						  $self->{'args'}->get_arg_names(3) ] );

    $self->add_indicator_dependency($self->{'sma1'}, 1);
    $self->add_indicator_dependency($self->{'sma2'}, 1);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name;

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $sma1 = $indic->get($self->{'sma1'}->get_name, $i);
    my $sma2 = $indic->get($self->{'sma2'}->get_name, $i);

    my $ravi = ($sma2 == 0) ? 0 : abs( 100 * ($sma1 - $sma2) / $sma2 );

    $indic->set($name, $i, $ravi);
}

1;
