package GT::Signals::Systems::MacdDiff;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Prices;
use GT::Indicators::MACD;

@ISA = qw(GT::Signals);
@NAMES = ("MacdDiffHigh", "MacdDiffLow");

=pod

=head1 GT::Signals::MacdDiff

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;

    my $self = { "args" => defined($args) ? $args : [12,26,9] };
    
    $args->[0] = 12 if (! defined($args->[0]));
    $args->[1] = 26 if (! defined($args->[1]));
    $args->[2] = 9  if (! defined($args->[2]));
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my ($self) = @_;
    
    $self->{'macd'} = GT::Indicators::MACD->new($self->{'args'});

    $self->add_indicator_dependency($self->{'macd'}, 3);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $q = $calc->prices;
    my $name_high = $self->get_name(0);
    my $name_low = $self->get_name(1);
    my $diff_name = $self->{'macd'}->get_name(2);

    return if (! $self->check_dependencies($calc, $i));

    my $today = $calc->indicators->get($diff_name, $i);
    my $yesterday = $calc->indicators->get($diff_name, $i - 1);
    my $before = $calc->indicators->get($diff_name, $i - 2);
    if ( # Yesterday is a local high on macddiff 
	 $today < $yesterday and $yesterday > $before
       )
    {
	$calc->signals->set($name_high, $i, 1);
    } else {
	$calc->signals->set($name_high, $i, 0);
    }

    if ( # Yesterday is a local bottom 
	 $yesterday < $today and $yesterday < $before
       )
    {
	$calc->signals->set($name_low, $i, 1);
    } else { 
	$calc->signals->set($name_low, $i, 0);
    }
}    

1;
