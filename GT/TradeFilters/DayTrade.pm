package GT::TradeFilters::DayTrade;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Prices;
use GT::TradeFilters;
use GT::Eval;
use GT::Tools qw(:generic);
use GT::DateTime;

@ISA = qw(GT::TradeFilters);
@NAMES = ("TFDayTrade[#*]");
@DEFAULT_ARGS = (5, 5);

=head1 NAME

TradeFilters::Generic - Accept or refuse trades based on specific signals

=head1 DESCRIPTION

This tradefilter takes two signals as parameter. The first decides if a buy
order is allowed, the second one decides if a sell order is allowed. If 
you don't precise a parameter, the corresponding orders will be refused.

=head1 EXAMPLES

Allow buy orders only when SMA 20 is moving up and sell orders when
SMA 20 is decreasing :

  TF:Generic {S:Generic:Increase {I:SMA 20}} {S:Generic:Decrease {I:SMA 20}}

=cut


sub initialize {
    my ($self) = @_;
}

my $prev_day_ptr;

sub accept_trade {
    my ($self, $order, $i, $calc, $portfolio) = @_;

    my $pi = $calc->prices->at($i);
    unless ($prev_day_ptr->{$i}) {
        my $x = $i;
        while (--$x && !$prev_day_ptr->{$i}) {
            my $p = $calc->prices->at($x);
            if (GT::DateTime::convert_date($pi->[$DATE], $calc->prices->timeframe, $DAY) ne
                    GT::DateTime::convert_date($p->[$DATE], $calc->prices->timeframe, $DAY)) {
                $prev_day_ptr->{$i} = $x;
            }
            else {
                $prev_day_ptr->{$i} = $prev_day_ptr->{$x}
                    if $prev_day_ptr->{$x};
            }
        }
    }

    my $prev_day_i = $prev_day_ptr->{$i};
    my $prev_close = $calc->prices->at($prev_day_i)->[$CLOSE];

    my $day_change_limit = $self->{'args'}->get_arg_constant(1);
    if (_find_lowv($calc, $prev_day_i+1, $i) < $prev_close * (1-$day_change_limit/100) ||
        _find_highv($calc, $prev_day_i+1, $i) > $prev_close * (1+$day_change_limit/100)) {
        return 0;
    }

    my $price_limit = $self->{'args'}->get_arg_constant(1);
#    warn "at ".$pi->[$DATE];
#    warn "==> prev close is ".$prev_close." at ".$calc->prices->at($prev_day_i)->[$DATE];
#    warn "range: ".join(' ', $prev_close * (1-$price_limit/100), $prev_close * (1+$price_limit/100));
    if ($order->is_buy_order()) {
        if ($order->price > $prev_close * (1 + $price_limit/100)) {
#            warn "discarding overpriced buy order (@{[ $order->price ]}) at ".$pi->[$DATE];
            return 0;
        }
        return 1;
    } else {
        if ($order->price < $prev_close * (1 - $price_limit/100)) {
#            warn "discarding underpriced sell order (@{[ $order->price ]}) at ".$pi->[$DATE];
#            warn "prev close is $prev_close, down $price_limit% = ".$prev_close * (1 - $price_limit/100);
            return 0;
        }
        return 1;
    }
}

sub _find_lowv {
    my ($calc, $from, $to) = @_;
#    warn "===> find low $from $to";
    my $low = $from;
    for (my $i = $from+1; $i<=$to; ++$i) {
        $low = $i
            if $calc->prices->at($i)->[$LOW] <= $calc->prices->at($low)->[$LOW];
    }
    return $calc->prices->at($low)->[$LOW];
}

sub _find_highv {
    my ($calc, $from, $to) = @_;
#    Carp::cluck unless defined $to;
    my $high = $from;
    for (my $i = $from+1; $i<=$to; ++$i) {
        $high = $i
            if $calc->prices->at($i)->[$HIGH] >= $calc->prices->at($high)->[$HIGH];
    }
    return $calc->prices->at($high)->[$HIGH];
}

1;
