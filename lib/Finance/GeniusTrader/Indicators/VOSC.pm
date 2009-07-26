package GT::Indicators::VOSC;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::SMA;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("VOSC[#1]", "VOSC-volume[#1]");
@DEFAULT_ARGS = (7);

=head1 NAME

GT::Indicators::VOSC - 

=head1 OVERVIEW

=head1 CALCULATION

=head1 EXAMPLES

GT::Indicators::VOSC->new()
GT::Indicators::VOSC->new([20])

=head1 LINKS

=cut

sub initialize {
    my $self = shift;
    
    # Initialize SMA
    $self->{'sma'} = GT::Indicators::SMA->new([ $self->{'args'}->get_arg_names(1), "{I:Generic:ByName ". $self->get_name(1) ."}"]);

    # Can't add this dependency since the indicator will not be
    # able to be computed at the check time

    #$self->add_indicator_dependency($self->{'sma'}, 1); 
    $self->add_prices_dependency($self->{'args'}->get_arg_constant(1));
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $vosc_name = $self->get_name(0);
    my $volume_name = $self->get_name(1);
    my $volume = 0;

    return if ($indic->is_available($vosc_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Determine how much days are required for the calculation
    my $nb_days = $self->{'args'}->get_arg_values($calc, $i, 1);

    for (my $n = 0; $n < $nb_days; $n++) {

	# Return if volume is available 
	next if $indic->is_available($volume_name, $i - $n);

	# Calculate volume
	if ($prices->at($i - $n)->[$CLOSE] > $prices->at($i - $n)->[$OPEN]) {
	    $volume = $prices->at($i - $n)->[$VOLUME];
	}
	if ($prices->at($i - $n)->[$CLOSE] < $prices->at($i - $n)->[$OPEN]) {
	    $volume = -$prices->at($i - $n)->[$VOLUME];
	}
	if ($prices->at($i - $n)->[$CLOSE] eq $prices->at($i - $n)->[$OPEN]) {
	    $volume = 0;
	}

	# Return results
	$indic->set($volume_name, $i - $n, $volume);

    }

    # Calculate and get VOSC
    $self->{'sma'}->calculate($calc, $i);
    my $vosc_value = $indic->get($self->{'sma'}->get_name, $i);

    # Return the results
    $indic->set($vosc_name, $i, $vosc_value);
}

1;
