package Finance::GeniusTrader::CloseStrategy::DayTrade;

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::CloseStrategy;
use Finance::GeniusTrader::Tools qw(:generic);
use Finance::GeniusTrader::Indicators::Hour;

@ISA = qw(Finance::GeniusTrader::CloseStrategy);
@NAMES = ("CSDayTrade[#*]");
@DEFAULT_ARGS = ('1325');

sub initialize {
    my ($self) = @_;
    $self->{hour} = Finance::GeniusTrader::Indicators::Hour->new;
    $self->add_indicator_dependency($self->{'hour'}, 1);
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return 0 if (! $self->check_dependencies($calc, $i));

    return unless $calc->indicators->get($self->{hour}->get_name, $i) == $self->{'args'}->get_arg_constant(1);

    my $order = $pf_manager->virtual_sell_at_close($calc, $sys_manager->get_name);
    $pf_manager->submit_order_in_position($position, $order, $i, $calc);

    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    return 0 if (! $self->check_dependencies($calc, $i));

    return unless $calc->indicators->get($self->{hour}->get_name, $i) == $self->{'args'}->get_arg_constant(1);

    my $order = $pf_manager->virtual_buy_at_close($calc, $sys_manager->get_name);
    $pf_manager->submit_order_in_position($position, $order, $i, $calc);

    return;
}

1;
