package GT::Indicators::PERF;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Tools;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("PERF[#1,#2]");
@DEFAULT_ARGS = (0, "{I:Prices CLOSE}");

=head1 GT::Indicators::PERF

The performance indicator display a security's price performance from
a reference day as a percentage. If the market is not available for
the reference day, use nearest preceding day.

Note: The day must be given in GT internal format and must match the timeframe.

Example :
GT::Indicators::PERF->new(["2001-09-22"]);
GT::Indicators::PERF->new(["2001-09-22", "{I:Prices VOLUME}"]);

=head2 GT::Indicators::PERF::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;

    my $reference = $self->{'reference'};
    unless ( defined $reference ) {

      my $date = $self->{'args'}->get_arg_constant(1);
      if ( $date ) {
	$date = $prices->find_nearest_preceding_date($date);
	$reference = $prices->date($date);
      } else {
	$reference = $i;
	$date = $prices->at($i)->[$DATE];
	my $name = $self->{'names'}->[0];
	$name =~ s/PERF\[0,/PERF[$date,/o;
        $self->{'names'}->[0] = $name;
      }

      $self->{'reference'} = $reference;

    }

    my $performance_name = $self->get_name(0);
    
    return if ($indic->is_available($performance_name, $i));
    
    # Calculate the performance of a security from a reference day in percentage
    my $performance = ((($self->{'args'}->get_arg_values($calc, $i, 2) - $self->{'args'}->get_arg_values($calc, $reference, 2)) / $self->{'args'}->get_arg_values($calc, $reference, 2)) * 100);
    
    $indic->set($performance_name, $i, $performance);
}

1;
