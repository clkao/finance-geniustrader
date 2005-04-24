package GT::Systems::TFS;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use Carp::Datum;
use GT::Prices;
use GT::Systems;
use GT::Indicators::TETHER;
use GT::Indicators::VOSC;

@ISA = qw(GT::Systems);
@NAMES = ("TFS[#1,#2]");

=head1 Trend Following System (TFS)

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [50, 7] };

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;

    $self->{'tether'} = GT::Indicators::TETHER->new([ $self->{'args'}[0] ]);
    $self->{'vosc'} = GT::Indicators::VOSC->new([ $self->{'args'}[1] ]);

    $self->add_indicator_dependency($self->{'tether'}, 2);
    $self->add_indicator_dependency($self->{'vosc'}, 1);
    $self->add_prices_dependency(2);
}


sub long_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    
    return DVAL 0 if (! $self->check_dependencies($calc, $i));
    
    if ( ( $calc->prices->at($i)->[$CLOSE] > 
	   $calc->indicators->get($self->{'tether'}->get_name, $i) )
	 &&
 	 ( $calc->prices->at($i - 1)->[$CLOSE] <= 
	   $calc->indicators->get($self->{'tether'}->get_name, $i - 1) )
	 &&
	 ( $calc->indicators->get($self->{'vosc'}->get_name, $i) > 0 )
       )
    {
	return DVAL 1;
    }
    return DVAL 0;
}

sub short_signal {
    DFEATURE my $f;
    my ($self, $calc, $i) = @_;
    
    return DVAL 0 if (! $self->check_dependencies($calc, $i));

    if ( ( $calc->prices->at($i)->[$CLOSE] < 
	   $calc->indicators->get($self->{'tether'}->get_name, $i) )
	 &&
 	 ( $calc->prices->at($i - 1)->[$CLOSE] >= 
	   $calc->indicators->get($self->{'tether'}->get_name, $i - 1) )
	 &&
	 ( $calc->indicators->get($self->{'vosc'}->get_name, $i) < 0 )
       )
    {
	return DVAL 1;
    }
    return DVAL 0;
}

1;
