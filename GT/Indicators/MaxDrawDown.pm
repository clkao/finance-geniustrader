package GT::Indicators::MaxDrawDown;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("MaxDrawDown");

=pod

=head1 GT::Indicators::MaxDrawDown

=head2 Overview

Calculate the MaxDrawDown, which is the worst percentage loss after reaching a maximum.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args, $key, $func) = @_;
    my $self = { 'args' => defined($args) ? $args : [] };
    
    if (defined($func)) {
	$self->{'_func'} = $func;
    } else {
	$self->{'_func'} = $GET_LAST;
	$key = 'LAST';
    }

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, $key);
}

sub initialize {
    my ($self) = @_;

    $self->add_prices_dependency(2);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $nb = $self->{'args'}[0];
    my $getvalue = $self->{'_func'};
    my $name = $self->get_name;
    my $current_draw_down = 0;
    my $max_draw_down = 0;
    
    return if (! $self->check_dependencies($calc, $i));

    my $high = &$getvalue($calc, 0);
    
    for (my $n = 0; $n <= $i; $n++) {
	
	if (&$getvalue($calc, $n) > $high) {
	    $high = &$getvalue($calc, $n);
	} else {
	    $current_draw_down = ($high - &$getvalue($calc, $n)) * 100 / $high;
	}
	if ($current_draw_down > $max_draw_down) {
	    $max_draw_down = $current_draw_down;
	}
	
    }
    $calc->indicators()->set($name, $i, $max_draw_down);
}

sub calculate_interval {
    my ($self, $calc, $first, $last) = @_;

    $self->calculate($calc, $last);
}

1;
