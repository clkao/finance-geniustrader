package GT::Systems::SMA;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Carp::Datum;
use GT::Prices;
use GT::Systems;
use GT::Indicators::SMA;

@ISA = qw(GT::Systems);
@NAMES = ("SMA[#1,#2,#3]");

=pod

=head1  Stochastic

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [5, 20, 10] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;

    $self->{'sma1'} = GT::Indicators::SMA->new([ $self->{'args'}[0] ]);
    $self->{'sma2'} = GT::Indicators::SMA->new([ $self->{'args'}[1] ]);
    $self->{'sma3'} = GT::Indicators::SMA->new([ $self->{'args'}[2] ]);

    $self->{'allow_multiple'} = 0;

    $self->add_indicator_dependency($self->{'sma1'}, 2);
    $self->add_indicator_dependency($self->{'sma2'}, 2);
    $self->add_indicator_dependency($self->{'sma3'}, 2);
}


sub long_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    
    return DVAL 0 if (!$self->check_dependencies($calc, $i));
    
    if ( ( $indic->get($self->{'sma1'}->get_name, $i - 1) <
  	   $indic->get($self->{'sma2'}->get_name, $i - 1)) &&
 	 ( $indic->get($self->{'sma1'}->get_name, $i) >
	   $indic->get($self->{'sma2'}->get_name, $i) )
       )
    {
	return DVAL 1;
    }
    return DVAL 0;
}

sub short_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    
    return DVAL 0;
}
