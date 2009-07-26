package GT::Signals::Trend::TTT;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Prices;
use GT::Indicators::HilbertPeriod;
use GT::Indicators::InstantTrendLine;

@ISA = qw(GT::Signals);
@NAMES = ("TTTUp", "TTTDown");

=head1 GT::Signals::Trend::TTT

Trade The Trend !! Use Hilbert period to detect the start of a trend.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [] };
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;
    
    $self->{'median'} = GT::Indicators::WTCL->new([0]);
    $self->{'period'} = GT::Indicators::HilbertPeriod->new;
    $self->{'trend'} = GT::Indicators::InstantTrendLine->new;

    $self->add_indicator_dependency($self->{'median'}, 2);
    $self->add_indicator_dependency($self->{'trend'}, 2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name_up = $self->get_name(0);
    my $name_down = $self->get_name(1);

    return if ($calc->signals->is_available($name_up, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $period = $indic->get($self->{'period'}->get_name, $i);

    return if ($i < $period);
    
    $self->{'median'}->calculate_interval($calc, $i - $period, $i);
    $self->{'trend'}->calculate_interval($calc, $i - $period, $i);

    return if (! $indic->is_available_interval($self->{'trend'}->get_name,
					       $i - $period, $i));
    
    my ($above, $below) = (0, 0);
    for (my $n = 0; $n <= $period; $n++) {
	if ($indic->get($self->{'median'}->get_name, $i - $n) >
	    $indic->get($self->{'trend'}->get_name, $i - $n))
	{
	    $above++;
	    last if ($below);
	} else {
	    $below++;
	    last if ($above);
	}
    }

    if (($above > $below) and ($above >= $period / 2))
    {
	$calc->signals->set($name_up, $i, 1);
    } else {
	$calc->signals->set($name_up, $i, 0);
    }

    if (($below > $above) and ($below >= $period / 2))
    {
        $calc->signals->set($name_down, $i, 1);
    } else {
        $calc->signals->set($name_down, $i, 0);
    }
}

sub detect_interval {
    my ($self, $calc, $first, $last) = @_;

    $self->{'period'}->calculate_interval($calc, $first, $last);
    $self->{'trend'}->calculate_interval($calc, $first, $last);
    $self->{'median'}->calculate_interval($calc, $first, $last);
    
    GT::Signals::detect_interval(@_);
}

1;
