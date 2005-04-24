package GT::Signals::Graphical::CandleSticks::InvertedHammer;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Prices;
use GT::Indicators::CNDL;

@ISA = qw(GT::Signals);
@NAMES = ("InvertedHammer");

=head1 GT::Signals::Graphical::CandelSticks::InvertedHammer

=head2 Overview

Inverted Hammers are just the opposite of Hammers (see
GT::Signals::Graphical::CandleSticks::Hammer), i.e., a small body occurs
at the bottom of a long trail. Black Inverted Hammers occuring at the end
of uptrends are clearly bearish, since the markets fails in its attempt to
rally higher, closing near the open.

However, white Inverted Hammers at the end of downtrends are more subtle,
and it is important to establish the following day as bullish. It is
likely that a short-covering rally will ensue, thereby confirming the
reversal.

=head2 Construction

An inverted Hammer is formed when the open, close and low occur at
approximately the same price, with a high extended significantly above the
three. The farther away the high is for the day, the more signifiant the
pattern in terms of forecasting a reversal.

=head2 Representation


              |       |       |     |
 |     |      |       |       |     |
 |     |     _|_     _|_      |     |
 |     |    |   |   |   |    ###   ###
---   ---   |___|   |___|    ###   ###
       |              |             |

 79    78     95      94      47    46


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
    
    $self->{'cndl'} = GT::Indicators::CNDL->new($self->{'args'});

    $self->add_indicator_dependency($self->{'cndl'}, 1);
}

sub detect {
    my ($self, $calc, $i) = @_;
    my $cndl_name = $self->{'cndl'}->get_name(0);
    my $inverted_hammer_name = $self->get_name(0);;

    return if ($calc->signals->is_available($self->get_name(0), $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $cndl_code = $calc->indicators->get($cndl_name, $i);

    if (($cndl_code eq 46) or ($cndl_code eq 78) or ($cndl_code eq 94) or
	($cndl_code eq 47) or ($cndl_code eq 79) or ($cndl_code eq 95)) {
	$calc->signals->set($inverted_hammer_name, $i, 1);
    } else { 
	$calc->signals->set($inverted_hammer_name, $i, 0);
    }
}    

1;
