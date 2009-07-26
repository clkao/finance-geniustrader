package Finance::GeniusTrader::Indicators::CMO;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Tools qw(:math);
use Finance::GeniusTrader::ArgsTree;
use Finance::GeniusTrader::Indicators::Generic::SumUpDiffs;
use Finance::GeniusTrader::Indicators::Generic::SumDownDiffs;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("CMO[#*]");
@DEFAULT_ARGS = (10, "{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::CMO - Chande Moment Oscillator

=head1 DESCRIPTION 

The CMO indicator was developed by Trushar Chande and presented 1994
in the book "The New Technical Trader". It can be used as an oscillator
(CMO > 50 => overbought, CMO < -50 => oversold) or as a trend indicator 
(the higher/lower the CMO, the stronger the trend)

   CMO = 100 * (SumUp-SumDown) / (SumUp+SumDown)


=head2 Parameters

=over

=item Period (default 10)

This argument is used to calculate the SumUp and SumDown.

=back

=head2 Creation

 Finance::GeniusTrader::Indicators::CMO->new()

=head2 Links

=cut


sub initialize {
    my $self = shift;

    $self->{'sumup'} = Finance::GeniusTrader::Indicators::Generic::SumUpDiffs->new( [ $self->{'args'}->get_arg_names(1), 
								   $self->{'args'}->get_arg_names(2) ] );
    $self->{'sumdown'} = Finance::GeniusTrader::Indicators::Generic::SumDownDiffs->new( [ $self->{'args'}->get_arg_names(1),
								   $self->{'args'}->get_arg_names(2) ] );

}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name;
    my $sumup_name = $self->{'sumup'}->get_name;
    my $sumdown_name = $self->{'sumdown'}->get_name;
    my $length = $self->{'args'}->get_arg_values($calc, $i, 1);

    # Calculate the depencies
    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency( $self->{'sumup'}, $length );
    $self->add_volatile_indicator_dependency( $self->{'sumdown'}, $length );

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i) );

    my $sumup = $indic->get($sumup_name, $i);
    my $sumdown = $indic->get($sumdown_name, $i);
    if ($sumup + $sumdown == 0) 
    {
        $sumup += 0.00001;
    }

    my $cmo = 100 * ($sumup - $sumdown) / ($sumup + $sumdown);

    $indic->set($name, $i, $cmo);

}

1;
