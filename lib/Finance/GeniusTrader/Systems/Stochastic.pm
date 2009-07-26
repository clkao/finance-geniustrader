package Finance::GeniusTrader::Systems::Stochastic;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Systems;
use Finance::GeniusTrader::Indicators::STO;

@ISA = qw(Finance::GeniusTrader::Systems);
@NAMES = ("Stochastic[#1,#2,#3,#4]");

=pod

=head1  Stochastic

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [9, 3, 3, 3] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;

    $self->{'sto'} = Finance::GeniusTrader::Indicators::STO->new($self->{'args'});

    $self->{'allow_multiple'} = 0;

    $self->add_indicator_dependency($self->{'sto'}, 1);;
}


sub long_signal {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    
    return 0 if (!$self->check_dependencies($calc, $i));

    if ( ( $indic->get($self->{'sto'}->get_name(2), $i) < 80 ) &&
 	 ( $indic->get($self->{'sto'}->get_name(1), $i) >
	   $indic->get($self->{'sto'}->get_name(3), $i) )
       )
    {
	return 1;
    }
    return 0;
}

sub short_signal {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    
    return 0 if (!$self->check_dependencies($calc, $i));

    if ( ( $indic->get($self->{'sto'}->get_name(2), $i) > 20 ) &&
 	 ( $indic->get($self->{'sto'}->get_name(1), $i) <
	   $indic->get($self->{'sto'}->get_name(3), $i) )
       )
    {
	return 1;
    }
    return 0;
}
