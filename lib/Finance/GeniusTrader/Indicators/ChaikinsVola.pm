package GT::Indicators::ChaikinsVola;

# Copyright 2002 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::Tools qw(:math);
use GT::ArgsTree;
use GT::Indicators::ROC;

@ISA = qw(GT::Indicators);
@NAMES = ("ChaikinsVola[#*]");
@DEFAULT_ARGS = (10,10,"{I:Prices HIGH}","{I:Prices LOW}");

=head1 NAME

GT::Indicators::ChaikinsVola - Chaikins Volatility

=head1 DESCRIPTION 

This is calculated as the Rate of change of an Moving Average of the
difference between High and Low.

=head2 Parameters

=over

=item Period 1

The Period used for the ROC.

=item Period 2

The Period used for the MA.

=item High

=item Low

=back

=cut


sub initialize {
    my $self = shift;
    my $diff = "{I:Generic::Eval " . $self->{'args'}->get_arg_names(3). " - " .
      $self->{'args'}->get_arg_names(4) . "}";
    my $sma = "{I:SMA " . $self->{'args'}->get_arg_names(2) . " " . $diff . "}";

    $self->{'roc'} = GT::Indicators::ROC->new( [ $self->{'args'}->get_arg_names(1), $sma ]);
    $self->add_indicator_dependency($self->{'roc'}, 1);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $roc = $self->{'roc'}->get_name();
    my $name = $self->get_name();

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i) );

    $indic->set($name, $i, $indic->get($roc, $i));
}

1;
