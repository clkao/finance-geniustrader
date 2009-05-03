package GT::CloseStrategy::Stop::SAR;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# Modified 2004 by Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::CloseStrategy;
use GT::Indicators::SAR;
use GT::Prices;

@ISA = qw(GT::CloseStrategy);
@NAMES = ("SAR[#1,#2,#3]");
@DEFAULT_ARGS = (0.02, 0.02, 0.20);

=head1 GT::CloseStrategy::Stop::SAR

=head2 Overview

This strategy end up a position once prices have crossed the trailing stop
determined by the Parabolic SAR (Stop And Reversal).

=head2 Note

Keep in mind that some source say "the SAR value is today's, not tomorrow's stop level" and other don't ! :)

Using the Parabolic SAR can be very helpful as long as the security is
not prone to short term price trend reversals.  If price is erratic,
reversing quickly in the short trend, the Parabolic SAR will likely
produce poor results.
				      
=head2 Links

http://www.stockcharts.com/education/Resources/Glossary/parabolicSAR.html
http://www.equis.com/free/taaz/parabolicsar.html
http://www.linnsoft.com/tour/techind/sar.htm

=cut

sub initialize {
    my ($self) = @_;

    $self->{'sar'} = GT::Indicators::SAR->new([ $self->{'args'}->get_arg_names(1),
						$self->{'args'}->get_arg_names(2),
						$self->{'args'}->get_arg_names(3) ]);
 
    $self->add_indicator_dependency($self->{'sar'}, 1);
    $self->add_prices_dependency(1);
}

sub get_indicative_long_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;
    my $stop = 0;

    return 0 if (! $self->check_dependencies($calc, $i));
    
    my $sar = $calc->indicators->get($self->{'sar'}->get_name, $i);
    
    # Place the trailing stop only then SAR and Prices are moving together
    if ($sar < $calc->prices->at($i)->[$LOW]) {
	$stop = $sar;
    }
    return $stop;
}

sub get_indicative_short_stop {
    my ($self, $calc, $i, $order, $pf_manager, $sys_manager) = @_;
    my $stop = 0;

    return 0 if (! $self->check_dependencies($calc, $i));
    
    my $sar = $calc->indicators->get($self->{'sar'}->get_name, $i);
    
    # Place the trailing stop only then SAR and Prices are moving together
    if ($sar > $calc->prices->at($i)->[$HIGH]) {
	$stop = $sar;
    }
    return $stop;
}

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return if (! $self->check_dependencies($calc, $i));
    
    my $sar = $calc->indicators->get($self->{'sar'}->get_name, $i);
    
    # Place the trailing stop only then SAR and Prices are moving together
    # Otherwise, exit immediately.
    if ($sar < $calc->prices->at($i)->[$LOW]) {
	$position->force_stop($sar);
    } else {
	my $order = $pf_manager->sell_market_price($calc, $sys_manager->get_name);
        $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }
    
    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    return if (! $self->check_dependencies($calc, $i));
 
    my $sar = $calc->indicators->get($self->{'sar'}->get_name, $i);

    # Place the trailing stop only then SAR and Prices are moving together
    # Otherwise, exit immediately.
    if ($sar > $calc->prices->at($i)->[$HIGH]) {
        $position->force_stop($sar);
    } else {
        my $order = $pf_manager->buy_market_price($calc, $sys_manager->get_name);
        $pf_manager->submit_order_in_position($position, $order, $i, $calc);
    }

    return;
}

1;
