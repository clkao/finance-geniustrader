package GT::Signals::Trend::HilbertChannelBreakout;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Prices;
use GT::Indicators::HilbertPeriod;

@ISA = qw(GT::Signals);
@NAMES = ("HCBUp[#1,#2,#3,#4]", "HCBDown[#1,#2,#3,#4]");

=head1 GT::Signals::Trend::HilbertChannelBreakout

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [ 15, 15, 0, 0 ] };
    
    $args->[0] = 15 if (! defined($args->[0]));
    $args->[1] = 15 if (! defined($args->[1]));
    $args->[2] = 0 if (! defined($args->[2]));
    $args->[3] = 0 if (! defined($args->[3]));
	    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;
    
    $self->{'period'} = GT::Indicators::HilbertPeriod->new();
    $self->add_indicator_dependency($self->{'period'}, 1);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $name_up = $self->get_name(0);
    my $name_down = $self->get_name(1);
    my $entry_value = $self->{'args'}[0];
    my $exit_value = $self->{'args'}[1];
    my $entry_k = $self->{'args'}[2];
    my $exit_k = $self->{'args'}[3];    
    my $entry_look_back = 0;
    my $exit_look_back = 0;

    return if ($calc->signals->is_available($name_up, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $period = $indic->get($self->{'period'}->get_name, $i);

    return if ($i < $period);
    
    if (defined($entry_value) && $entry_value != 0) {
	$entry_look_back = $entry_value;
    } else {
	$entry_look_back = $entry_k * $period;
    }
    
    if (defined($exit_value) && $exit_value != 0) {
	$exit_look_back = $exit_value;
    } else {
	$exit_look_back = $exit_k * $period;
    }
    
    $entry_look_back = 1 if ($entry_look_back < 1);
    $exit_look_back = 1 if ($exit_look_back < 1);
    
    my $entry_channel = $prices->at($i - 1)->[$HIGH];
    for (my $n = 1; $n <= $entry_look_back; $n++) {

	if ($entry_channel < $prices->at($i - $n)->[$HIGH]) {
	    $entry_channel = $prices->at($i - $n)->[$HIGH];
	}
    }
    
    my $exit_channel = $prices->at($i - 1)->[$LOW];
    for (my $n = 1; $n <= $exit_look_back; $n++) {

        if ($exit_channel > $prices->at($i - $n)->[$LOW]) {
            $exit_channel = $prices->at($i - $n)->[$LOW];
        }
    }
	    
    if ($prices->at($i)->[$HIGH] > $entry_channel) {
	$calc->signals->set($name_up, $i, 1);
    } else {
	$calc->signals->set($name_up, $i, 0);
    }

    if ($prices->at($i)->[$LOW] < $exit_channel) {
        $calc->signals->set($name_down, $i, 1);
    } else {
        $calc->signals->set($name_down, $i, 0);
    }
}

sub detect_interval {
    my ($self, $calc, $first, $last) = @_;

    $self->{'period'}->calculate_interval($calc, $first, $last);
    GT::Signals::detect_interval(@_);
}

1;
