package GT::Indicators::GMEAN;

# Copyright 2008 Andreas Hartmann
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("GMEAN[#1,#2]");
@DEFAULT_ARGS=("{I:Prices HIGH}", "{I:Prices LOW}");

=head1 GT::Indicators::GMEAN

=head2 Overview

The geometric mean indicator calculates the geometic mean of each days high and low.
While the arithmetic mean has an equal absolute distance to high and low,
the geometric mean has an equal relative distance to high and low.

arithmetic mean: high - mean = mean - low
geometric mean: high / gmean = gmean / low

=head2 Calculation

gmean = (high * low)^(1/2)

=head2 Links

=cut

sub initialize {
	my ($self) = @_;
	$self->add_arg_dependency(1, 1);
	$self->add_arg_dependency(2, 1);
}

sub calculate {
	my ($self, $calc, $i) = @_;
	my $name = $self->get_name;
	my $prices = $calc->prices;

	return if ($calc->indicators->is_available($name, $i));
	return if (! $self->check_dependencies($calc, $i));

	my $hi = $self->{'args'}->get_arg_values($calc, $i, 1);
	my $lo = $self->{'args'}->get_arg_values($calc, $i, 2);
	my $gmean = sqrt($hi * $lo);

	$calc->indicators->set($name, $i, $gmean);
}

1;

