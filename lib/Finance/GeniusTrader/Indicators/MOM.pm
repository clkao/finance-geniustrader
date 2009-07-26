package Finance::GeniusTrader::Indicators::MOM;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::ArgsTree;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("MOM[#*]");
@DEFAULT_ARGS = (12, "{I:Prices CLOSE}");

=head2 Finance::GeniusTrader::Indicators::MOM

The standard Momentum is the Momentum 12 days : Finance::GeniusTrader::Indicators::MOM->new()
If you need a non standard Momentum use for example : Finance::GeniusTrader::Indicators::MOM->new([9]) or Finance::GeniusTrader::Indicators::MOM->new([25])

=cut

sub initialize {
    my ($self) = @_;
}


=head2 Finance::GeniusTrader::Indicators::MOM::calculate($calc, $day)

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
