package Finance::GeniusTrader::Indicators::RMI;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::MOM;
use Finance::GeniusTrader::Indicators::EMA;


@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("RMI[#*]", "UpAvg[#*]", "DownAvg[#*]");
@DEFAULT_ARGS = (21,10,"{I:Prices CLOSE}");

=head1 NAME

Finance::GeniusTrader::Indicators::RMI - Relative Momentum Index

=head1 DESCRIPTION

=head2 Parameters

=over

=item Period (default 5)

The first argument is the period used to calculed the average.

=item Moment distance (default 10)

=back

=head2 Creation

 Finance::GeniusTrader::Indicators::RMI->new()
 Finance::GeniusTrader::Indicators::RMI->new([10,20])

=head2 Links

http://www.geocities.com/burzum_3/rmi.html

=cut

sub initialize {
    my ($self) = @_;
    $self->{'mom'} = Finance::GeniusTrader::Indicators::MOM->new( [ $self->{'args'}->get_arg_names(2), 
        $self->{'args'}->get_arg_names(3) ] );
}


sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $nb1 = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $nb2 = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $name = $self->get_name(0);
    my $upname = $self->get_name(1);
    my $downname = $self->get_name(2);

    return if (! defined($nb1) || ! defined($nb2) );

    # Calculate the depencies
    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency( $self->{'mom'}, $nb2 );

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $downsum = 0;
    my $upsum = 0;
    my $upavg = 0;
    my $downavg = 0;

    my $rmi = 0;
    my $diff;
    if ( ! ($calc->indicators->is_available($upname, $i-1) &&
	    $calc->indicators->is_available($downname, $i-1)) )
    {
	for(my $n = $i - $nb1 + 1; $n <= $i; $n++) 
	{
	    $diff = $calc->indicators->get($self->{'mom'}->get_name, $n);
	    if ($diff > 0)
	    {
		$upsum += $diff;
	    }
	    else {
		$downsum += -$diff;
	    }
	}
	$upavg = $upsum / $nb1;
	$downavg = $downsum / $nb1;
    }
    else {
	$diff = $calc->indicators->get($self->{'mom'}->get_name, $i);
	if ($diff > 0)
	{
	    $upsum = $diff;
	}
	else {
	    $downsum = -$diff;
	}
	$upavg = ($calc->indicators->get($upname, $i-1)*($nb1-1)+$upsum) / $nb1;
	$downavg = ($calc->indicators->get($downname, $i-1)*($nb1-1)+$downsum) / $nb1;
    }

    $rmi = ($upavg+$downavg==0) ? 0 : 100 * $upavg / ($upavg+$downavg);

    $calc->indicators->set($name, $i, $rmi);
    $calc->indicators->set($upname, $i, $upavg);
    $calc->indicators->set($downname, $i, $downavg);
}

