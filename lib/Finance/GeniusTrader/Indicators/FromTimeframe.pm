package Finance::GeniusTrader::Indicators::FromTimeframe;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::DateTime;
use Finance::GeniusTrader::Calculator;
use Finance::GeniusTrader::Tools qw(extract_object_number);

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("FromTimeframe[#*]");
@DEFAULT_ARGS = ("{I:Prices CLOSE}", "week", 0);

=head1 NAME

Finance::GeniusTrader::Indicators::FromTimeframe - Get data from an other timeframe

=head1 DESCRIPTION

If you need data from an other timeframe (e.g. to determine the trend
on weekly basis), you can use this indicator.

=head1 PARAMETERS

=over

=item Data

A normal indicators-/data-object.

=item Timeframe

The timeframe you want to get

=item Days

The number of periods you want to go back in the requested timeframe.

=back

=cut
sub initialize {
    my $self = shift;
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $code = $calc->{'code'};
    my $indic = $calc->indicators;
    my $nb = $self->{'args'}->get_arg_values($calc, $i, 3);

    # Initialize
    if (!defined($self->{$code}->{'special_calc'})) {
        $self->{$code}->{'special_tf'} = Finance::GeniusTrader::DateTime::name_to_timeframe($self->{'args'}->get_arg_constant(2));
        $self->{$code}->{'special_prices'} = $calc->prices->convert_to_timeframe($self->{$code}->{'special_tf'});
        $self->{$code}->{'special_calc'} = Finance::GeniusTrader::Calculator->new($self->{$code}->{'special_prices'});
	$self->{$code}->{'special_calc'}->set_code($calc->code());
    } else {
    }


    my $date = $calc->prices->at($i)->[$DATE];
    my $time = Finance::GeniusTrader::DateTime::map_date_to_time($calc->prices->timeframe(), $date);
    $date = Finance::GeniusTrader::DateTime::map_time_to_date($self->{$code}->{'special_tf'}, $time);

    if ($self->{$code}->{'special_prices'}->has_date($date)) {
        my $j = $self->{$code}->{'special_prices'}->date($date);
        my $tmp = $self->{'args'}->get_arg_names(1);
        $tmp =~ s/^{|}$//g;

        my $args = Finance::GeniusTrader::ArgsTree->new( $tmp );
        my $name_index = extract_object_number($args->get_arg_names(1));
	    my $ob = $self->{'args'}->get_arg_object(1);
	    $ob->calculate($self->{$code}->{'special_calc'}, $j - $nb);
	    my $res = $self->{$code}->{'special_calc'}->indicators->get($ob->get_name($name_index), $j - $nb);
        $indic->set($self->get_name, $i, $res);
    }

}

1;
