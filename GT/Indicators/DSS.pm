package GT::Indicators::DSS;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::ArgsTree;
use GT::Indicators;
use GT::Indicators::EMA;
use GT::Indicators::Generic::Divide;

@ISA = qw(GT::Indicators);
@NAMES = ("DSS-BLAU[#*]");
@DEFAULT_ARGS = (3,3,1,"{I:Prices CLOSE}");

=head1 NAME

GT::Indicators::DSS - The Double Smoothed Stochastic (William Blau)

=head1 DESCRIPTION 

The DSS is calculated as follows:

  DSS (p1, p2, p3) = EMA( EMA( Close - Lowest(p1), p2), p3 ) /
                          EMA( EMA( Highest(p1) - Lowest(p1), p2), p3 ) /

The handling and the calculations of signals is similar to the
Stochastic-Indictor.

=head2 Parameters

=over

=item Period 1 (default 3)

The period of the minimum/maximum.

=item Period 2 (default 3)

The period of the first EMA

=item Period 3 (default 1)

The period of the second EMA

=item Source 

The source of which the indicators is calculated.

=back

=head2 Creation


=head2 Link

This link is unfortunately only in german:

http://www.trading-konzepte.de/indikator/dss-blau.htm

=cut


sub initialize {
    my ($self) = @_;

    my $hhigh = "{Indicators::Generic::MaxInPeriod " . " " .
	$self->{'args'}->get_arg_names(1) . " " . $self->{'args'}->get_arg_names(4) . "}";
    my $llow = "{Indicators::Generic::MinInPeriod " .
	$self->{'args'}->get_arg_names(1) . " " . $self->{'args'}->get_arg_names(4) . "}";
    my $diff1 = "{Indicators::Generic::Eval " . $self->{'args'}->get_arg_names(4) . " - " . $llow . "}";
    my $diff2 = "{Indicators::Generic::Eval " . $hhigh . " - " . $llow . "}";

    $self->{'div'} = GT::Indicators::Generic::Divide->new( [ $diff1, $diff2 ] );

    $self->{'ema1'} = 
      GT::Indicators::EMA->new([ $self->{'args'}->get_arg_names(2) ], "EMA of div", 
			       sub { $_[0]->indicators->get($self->{'div'}->get_name, $_[1]) });
    $self->{'ema2'} = 
      GT::Indicators::EMA->new([ $self->{'args'}->get_arg_names(3) ], "EMA of EMA1", 
			       sub { $_[0]->indicators->get($self->{'ema1'}->get_name, $_[1]) });
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name();
    my $nb1 = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $nb2 = $self->{'args'}->get_arg_values($calc, $i, 2);
    my $nb3 = $self->{'args'}->get_arg_values($calc, $i, 3);

    return if (!defined($nb1) || !defined($nb2) || !defined($nb3) );

    # Calculate the depencies
    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency( $self->{'div'}, $nb1 * 3 - 2);
    $self->add_volatile_indicator_dependency( $self->{'ema1'}, $nb2 * 2 - 1 );
    $self->add_volatile_indicator_dependency( $self->{'ema2'}, $nb3 );

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    my $dss = $indic->get($self->{'ema2'}->get_name, $i);

    $indic->set($name, $i, $dss);
}

1;
