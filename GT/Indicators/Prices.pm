package GT::Indicators::Prices;

# Copyright 2000-2003 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0 

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Prices;
use GT::Eval;

@ISA = qw(GT::Indicators);
@NAMES = ("Prices[#*]");

=head1 NAME

GT::Indicators::Prices - Return the prices/volume/date of any share

=head1 DESCRIPTION

As you often need the prices while using Generic indicators, this
modules makes it easy for you to include prices through an indicator:
{I:Prices OPEN} or {I:Prices LOW 13330}

=head1 PARAMETERS

=over

=item Data

You have to tell in which data you're interested. You have to choose between
OPEN, HIGH, LOW, CLOSE, VOLUME, DATE.

=item Share

If you don't specify a second argument, you will use the data of the share
that you're working on. But sometimes you may want to use the prices of a
second share (for comparison, etc). In that case you can specify its code.

=back

=cut
sub initialize {
    my $self = shift;
    my $data = $CLOSE;
    
    # First parameter: which data
    if ($self->{'args'}->get_nb_args() > 0) {
	my $arg = $self->{'args'}->get_arg_constant(1);
	if ($arg =~ /OPEN|FIRST/i) { $data = $OPEN }
	elsif ($arg =~ /HIGH/i) { $data = $HIGH }
	elsif ($arg =~ /LOW/i) { $data = $LOW }
	elsif ($arg =~ /CLOSE|LAST/i) { $data = $CLOSE }
	elsif ($arg =~ /VOLUME/i) { $data = $VOLUME }
	elsif ($arg =~ /DATE/i) { $data = $DATE }
    }
    
    # Second parameter: code of the share
    if ($self->{'args'}->get_nb_args() > 1) {
	$self->{'use_std_prices'} = 0;
	my $db = create_standard_object("DB::" . GT::Conf::get("DB::module"));
	my $q = $db->get_prices($self->{'args'}->get_arg_constant(2));
	$self->{'special_prices'} = $q;
    } else {
	$self->{'use_std_prices'} = 1;
    }

    # Misc init
    $self->{'data_ind'} = $data;
}

sub calculate {
    my ($self, $calc, $i) = @_;

    return if ($calc->indicators->is_available($self->get_name, $i));

    my $indic = $calc->indicators;
    my $DATA = $self->{'data_ind'};
    
    if ($self->{'use_std_prices'}) {
	$indic->set($self->get_name, $i, $calc->prices->at($i)->[$DATA]);
    } else {
	my $prices = $self->{'special_prices'};
	my $date = $calc->prices->at($i)->[$DATE];
	if ($prices->has_date($date)) {
	    $indic->set($self->get_name, $i, $prices->at_date($date)->[$DATA]);
	}
    }
}

1;
