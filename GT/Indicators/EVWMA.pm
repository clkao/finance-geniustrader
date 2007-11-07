package GT::Indicators::EVWMA;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("EVWMA");
@DEFAULT_ARGS = ("{I:Prices CLOSE}");

=head1 GT::Indicators::EVWMA

=head2 Overview

The Elastic Volume Weighted Moving Average (eVWMA) differs from usual average in that :

- It does not refer to any underlying averaging time period (for example, 20 days, 50 days, 200 days). Instead, eVWMA uses share volume to define the period of the averaging.

- It incorporates information about volume (and possibly time) in a natural and logical way

- It can be derived from, and seen as an approximation to, a statistical measure and thus has a solid mathematical justification.

=head2 Calculation

eVWMA(0) = Today's Close
eVWMA(i) = ((Number of shares floating - Today's Volume) * eVWMA(i-1) + Today's Volume * Today's Close) / Number of shares floating

=head2 Example

GT::Indicators::EVWMA->new()

=head2 Links

http://www.christian-fries.de/evwma/
http://www.linnsoft.com/tour/techind/evwma.htm

=head2 GT::Indicators::EVWMA::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $getvalue = $self->{'_func'};
    my $evwma_name = $self->get_name(0);
    my $prices = $calc->prices;
    my $evwma = 0;

    # Return if we have already the required data
    return if ($calc->indicators->is_available($evwma_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Return if the metainfo file doesn't exist
    return if not (-e "/bourse/metainfo/" . $calc->code . ".xml");
       
    # Find the number of floating shares
    $calc->metainfo->load("/bourse/metainfo/" . $calc->code . ".xml");
    my $floating_shares = $calc->metainfo->get("floating_shares");
    
    for (my $n = 0; $n <= $i; $n++) {
    
	if ($n == 0) {
	    
	    # Set eVWMA(0) as Today's Close
	    $evwma = $self->{'args'}->get_arg_values($calc, $i, $n);
	    
	} else {

	    # Calculate the following eVWMA
	    $evwma = (($floating_shares - $prices->at($n)->[$VOLUME]) * $self->{'args'}->get_arg_values($calc, $i, $n - 1) + ($prices->at($n)->[$VOLUME] * self->{'args'}->get_arg_values($calc, $i, $n))) / $floating_shares;
	}
        $calc->indicators->set($evwma_name, $i, $evwma);
    }
}

1;
