package GT::Indicators::Range;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("Range[#*]");
@DEFAULT_ARGS = ("{I:Prices HIGH}", "{I:Prices LOW}");

=head1 GT::Indicators::Range

The range is nothing more than the difference between the high and the low
of the day.

=cut

sub initialize {
    my ($self) = @_;

    $self->add_arg_dependency(1,1);
    $self->add_arg_dependency(2,1);
}

=head2 GT::Indicators::Range::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $name = $self->get_name;

    return if ($calc->indicators->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
  
    my $range = $self->{'args'}->get_arg_values($calc, $i, 1) - $self->{'args'}->get_arg_values($calc, $i, 2);

    # Return the results
    $calc->indicators->set($name, $i, $range);
}

1;
