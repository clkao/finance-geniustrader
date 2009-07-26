package Finance::GeniusTrader::Analyzers::R4;

# Copyright 2003 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Analyzers;
use Finance::GeniusTrader::Calculator;

@ISA = qw(Finance::GeniusTrader::Analyzers);
@NAMES = ("R4[#*]");
@DEFAULT_ARGS = ("{A:WinRatio}", "{A:AvgNZ {A:Gain}}", "{A:AvgNZ {A:Losses}}", "{A:InitSum}" );

=head1 NAME

  Finance::GeniusTrader::Analyzers::AvgCosts - Average Costs per trade

=head1 DESCRIPTION 

The mean performance of the portfolio

=head2 Parameters

none

=cut

sub initialize {
    1;
}

sub calculate {
    my ($self, $calc, $last, $first, $portfolio) = @_;
    my $name = $self->get_name;

    if ( !defined($portfolio) ) {
	$portfolio = $calc->{'pf'};
    }
    if ( !defined($first) ) {
	$first = $calc->{'first'};
    }
    if ( !defined($last) ) {
	$last = $calc->{'last'};
    }

    # Calculate Vince's "R4" (Risk Of Ruin)
    # 
    # Example on system TFS with Alcatel :
    # There is a 19.2 % probability of the account falling 40 % below the start
    # equity (10 000 EUR) before it rises above 20 000 EUR.

    # Probability of a win
    my $PW = $self->{'args'}->get_arg_values($calc, $last, 1);

    # Average winning trade
    my $AW = $self->{'args'}->get_arg_values($calc, $last, 2);

    # Average losing trade
    my $AL = $self->{'args'}->get_arg_values($calc, $last, 3);

    # Size of starting account
    my $Q = $self->{'args'}->get_arg_values($calc, $last, 4);;

    # Quit trading and celebrate if account reaches this
    my $L = $Q * 2;

    # Drawdown to start equity that constitutes "ruin"
    my $G = 0.40;

    # Initialize the risk of ruin to 100 % before we calculate it, so that
    # the ratio is already set up if we have no winning trades...
    my $R4 = 1.0;
   
    # Calculate the risk or ruin only if we have some winning trades and
    # losing ones !
    if (($AW != 0) and ($AL != 0)) {
	my $a = sqrt( ($PW * ($AW / $Q) * ($AW / $Q)) + ((1.0 - $PW) * ($AL / $Q) * ($AL / $Q)) );
	my $z = (abs($AW / $Q) * $PW) - (abs($AL / $Q) * (1.0 - $PW));
	my $p = 0.5 * (1.0 + ($z / $a));
	my $U = $G / $a;
	my $c = (($L - ((1.0 - $G) * $Q)) / $Q) / $a;
	my $temp1 = exp($U * log((1.0 - $p) / $p));
	my $temp2 = exp($c * log((1.0 - $p) / $p));
	$R4 = (($temp2 - 1.0) != 0) ? 1.0 - (($temp1 - 1.0) / ($temp2 - 1.0)) : 0;
    }

    # Set up the risk of ruin to 0 % if we don't have losing trades !
    $R4 = 0 if ($AL eq 0);

    print STDERR $Q . " - " . $PW . "\n";

    $calc->indicators->set($name, $last, $R4);
}

1;
