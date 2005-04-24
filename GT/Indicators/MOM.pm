package GT::Indicators::MOM;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;
use GT::ArgsTree;

@ISA = qw(GT::Indicators);
@NAMES = ("MOM[#*]");
@DEFAULT_ARGS = (12, "{I:Prices CLOSE}");

=head2 GT::Indicators::MOM

The standard Momentum is the Momentum 12 days : GT::Indicators::MOM->new()
If you need a non standard Momentum use for example : GT::Indicators::MOM->new([9]) or GT::Indicators::MOM->new([25])

=cut

sub initialize {
    my ($self) = @_;
}


=head2 GT::Indicators::MOM::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $name = $self->get_name;
    my $mom = 0;

    $self->remove_volatile_dependencies();
    $self->add_volatile_arg_dependency(2,$nb+1);

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));

    $mom = $self->{'args'}->get_arg_values($calc, $i, 2) - 
      $self->{'args'}->get_arg_values($calc, $i - $nb + 1, 2);

    $calc->indicators->set($name, $i, $mom);
}
