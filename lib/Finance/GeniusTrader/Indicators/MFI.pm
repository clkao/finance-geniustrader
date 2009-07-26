package Finance::GeniusTrader::Indicators::MFI;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Indicators::TP;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("MFI[#1]");

=head1 Finance::GeniusTrader::Indicators::MFI

=head2 Overview

The Money Flow Index (MFI) is a momentum indicator that measures the strength of money flowing in and out of a security. It is related to the Relative Strength Index (RSI), but where the RSI only incorporates prices, the Money Flow Index accounts for volume.

=head2 Interpretation

Look for divergence between the indicator and the price action. If the price trends higher and the MFI trends lower (or vice versa), a reversal may be imminent.

Look for market tops to occur when the MFI is above 80. Look for market bottoms to occur when the MFI is below 20.

=head2 Calculation

The Money Flow Index requires a series of calculations.

Money Flow = Typical Price * Volume

If today's Typical Price is greater than yesterday's Typical Price, it is considered as a Positive Money Flow and if today's price is less, it is considered as a Negative Money Flow.

Positive Money Flow is the sum of the Positive Money over the specified number of periods. Negative Money Flow is the sum of the Negative Money over the specified number of periods.
										The Money Ratio is then calculated by dividing the Positive Money Flow by the Negative Money Flow.

Money Ratio = Positive Money Flow / Negative Money Flow

Money Flow Index = 100 - ( 100 / ( 1 + Money Ratio ))

=head2 Parameters

The standard MFI works with a fourteen-day parameter : n = 14

=head2 Example

Finance::GeniusTrader::Indicators::MFI->new()
Finance::GeniusTrader::Indicators::MFI->new([8])

=head2 Links

http://www.equis.com/free/taaz/moneyflow.html
http://www.linnsoft.com/tour/techind/mfi.htm

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args) = @_;
    my $self = { 'args' => defined($args) ? $args : [14] };

    $args->[0] = 14 if (! defined($args->[0]));
       
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my $self = shift;

    $self->{'tp'} = Finance::GeniusTrader::Indicators::TP->new();

    $self->add_indicator_dependency($self->{'tp'}, $self->{'args'}[0] + 1);
}

=pod

=head2 Finance::GeniusTrader::Indicators::TP::calculate($calc, $day)

=cut

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $period = $self->{'args'}[0];
    my $tp = $self->{'tp'};
    my $tp_name = $tp->get_name;
    my $today_typical_price = 0;
    my $yesterday_typical_price = 0;
    my $money_flow_index_name = $self->get_name(0);
    my $money_flow = 0;
    my $sum_of_positive_money_flow = 0;
    my $sum_of_negative_money_flow = 0;
    my $money_flow_index_value = 0;
    my $money_ratio = 0;

    return if ($indic->is_available($money_flow_index_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    for (my $n = $i - $period + 1; $n <= $i; $n++) {
        # Get the Typical Prices
        $today_typical_price = $indic->get($tp_name, $n);
	$yesterday_typical_price = $indic->get($tp_name, $n - 1);
	
        # Calculate the Money Flow
	$money_flow = $today_typical_price * $prices->at($n)->[$VOLUME];
	
	if ($today_typical_price > $yesterday_typical_price) {
	    $sum_of_positive_money_flow += $money_flow;
	}
	if ($today_typical_price < $yesterday_typical_price) {
	    $sum_of_negative_money_flow += $money_flow;
	}
    }

    if ($sum_of_negative_money_flow != 0) {
        $money_ratio = $sum_of_positive_money_flow / $sum_of_negative_money_flow;
        $money_flow_index_value = 100 - ( 100 / ( 1 + $money_ratio));
    }
    
    # Return the results
    $indic->set($money_flow_index_name, $i, $money_flow_index_value);
}

1;
