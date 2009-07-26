package Finance::GeniusTrader::Indicators::TRIX;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::ArgsTree;
use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::EMA;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("TRIX[#*]");
@DEFAULT_ARGS = (5);

=head1 NAME

Finance::GeniusTrader::Indicators::TRIX - TRIX-Indicator from Jack Hutson

=head1 DESCRIPTION 

The TRIX-Indicator was developed by John Hutson. It is a 1-day-ROC of
a threefold EMA (A EMA of a EMA of a EMA). It is calculated as:

    TRIX = 100 * ( EMA3(t) - EMA3(t-1) ) / EMA3(t-1)

The standard interpretation is that a signal is generated if the TRIX
cuts the zero-line. It is a relative stable yet not very effective
indicator because it generates the signals very late. You can combine
the TRIX with an EMA[9] to generate MACD-like signals.

=head2 Parameters

=over 

=item Period (default 5)

The first argument is the period used to calculed the average.

=back

=head2 Creation

 Finance::GeniusTrader::Indicators::TRIX->new()
 Finance::GeniusTrader::Indicators::TRIX->new([20])

=head2 Link

 http://www.incrediblecharts.com/technical/trix_indicator.htm

=cut


sub initialize {
    my ($self) = @_;

    $self->{'ema1'} = Finance::GeniusTrader::Indicators::EMA->new( [ $self->{'args'}->get_arg_names() ] );

    $self->{'ema2'} = Finance::GeniusTrader::Indicators::EMA->new([ $self->{'args'}->get_arg_names(1),
        "{I:EMA @{[$self->{'ema1'}->{'args'}->get_arg_names()]}}" ]);

    $self->{'ema3'} = Finance::GeniusTrader::Indicators::EMA->new([ $self->{'args'}->get_arg_names(1),
        "{I:EMA @{[$self->{'ema2'}->{'args'}->get_arg_names()]}}" ]);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $trix_name = $self->get_name(0);
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);

    return if (! defined($nb));

    # Calculate the depencies
    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency( $self->{'ema1'}, $nb * 5 - 4 );
    $self->add_volatile_indicator_dependency( $self->{'ema2'}, $nb * 4 - 3 );
    $self->add_volatile_indicator_dependency( $self->{'ema3'}, $nb * 3 - 2 );

    return if ($calc->indicators->is_available($trix_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $ema3_today = $indic->get($self->{'ema3'}->get_name, $i);
    my $ema3_yesterday = $indic->get($self->{'ema3'}->get_name, $i-1);
    my $trix = ($ema3_yesterday!=0) ? 100 * ( ($ema3_today-$ema3_yesterday)/$ema3_yesterday ) : 0;

    $indic->set($trix_name, $i, $trix);
}

1;
