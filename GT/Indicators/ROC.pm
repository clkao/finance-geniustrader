package GT::Indicators::ROC;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("ROC[#1,#2]");
@DEFAULT_ARGS = (12,"{I:Prices CLOSE}");

=head2 GT::Indicators::ROC

The Rate of Change (ROC) is similar to the Momentum.
The standard Rate of Change is the ROC 12 days : GT::Indicators::MOM->new()
If you need a non standard Momentum use for example : GT::Indicators::MOM->new([9]) or GT::Indicators::MOM->new([25])

=head2 Validation

This Indicator was validated by the data available from comdirect.de: 
The DAX at 04.06.2003 (data from yahoo.com) had a ROC of 8.05.
This is consistent with this indicator: 8.0451

=cut

sub intialize {
    my ($self) = @_;
}

=head2 GT::Indicators::ROC::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);

    my $name = $self->get_name;
    my $roc = 0;

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2,$nb);

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    if ( $self->{'args'}->get_arg_values($calc, $i-$nb+1, 2) != 0 )
    {
      $roc =  ( ( $self->{'args'}->get_arg_values($calc, $i, 2) - 
		  $self->{'args'}->get_arg_values($calc, $i - $nb , 2) ) / 
		$self->{'args'}->get_arg_values($calc, $i - $nb, 2)) * 100;
    }
    $calc->indicators->set($name, $i, $roc);
}

