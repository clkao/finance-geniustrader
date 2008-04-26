package GT::Indicators::PERF;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("PERF[#1,#2]");
@DEFAULT_ARGS = (0, "{I:Prices CLOSE}");

=head1 GT::Indicators::PERF

The performance indicator display a security's price performance from a reference day as a percentage.

If first parameter is omitted, uses the first price as a reference day.
(Note: In this case, uses "0" in name of indicator.)

Example :
GT::Indicators::PERF->new(["2001-09-22"]);
GT::Indicators::PERF->new(["2001-09-22", "{I:Prices VOLUME}"]);

=head2 GT::Indicators::PERF::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $reference = $self->{'args'}->get_arg_constant(1);
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $performance_name = $self->get_name(0);
    
    return if ($indic->is_available($performance_name, $i));
    
    # Make sure we already have a reference date
    $reference = $prices->at(0)->[$DATE] if (!$reference);
    my $item = $prices->date($reference);
    
    # Calculate the performance of a security from a reference day in percentage
    my $performance = ((($self->{'args'}->get_arg_values($calc, $i, 2) - $self->{'args'}->get_arg_values($calc, $item, 2)) / $self->{'args'}->get_arg_values($calc, $item, 2)) * 100);
    
    $indic->set($performance_name, $i, $performance);
}

1;
