package GT::Signals::Indicators::RSIUp;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Prices;
use GT::Indicators::RSI;

@ISA = qw(GT::Signals);
@NAMES = ("RSIUp[#1,#2]");

=head1 GT::Signals::Indicators::RSIDown

Signal when we cross up a limit on the RSI. Limit is 30 by default.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [30, 14] };
    $self->{'args'}[1] = 14 if (! defined($self->{'args'}[1]));
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;
    
    $self->{'rsi'} = GT::Indicators::RSI->new([ $self->{'args'}[1] ]);

    $self->add_indicator_dependency($self->{'rsi'}, 2);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $limit = $self->{'args'}[0];
    my $rsiname = $self->{'rsi'}->get_name;
    my $name = $self->get_name;

    return if ($calc->signals->is_available($name, $i));
    return if (! $self->check_dependencies($calc, $i));
    
    # Test if we have crossed the 30 limit
    if ( # RSI of $i-1 <= 30
	 $indic->get($rsiname, $i - 1) <= $limit &&

	 # RSI of $i > 30
	 $indic->get($rsiname, $i) > $limit
       )
    {
	$calc->signals->set($name, $i, 1);
    } else {
	$calc->signals->set($name, $i, 0);
    }
}

1;
