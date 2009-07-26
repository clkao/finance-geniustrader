package GT::Signals::Graphical::CandleSticks::Hammer;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Signals;
use GT::Prices;
use GT::Indicators::CNDL;

@ISA = qw(GT::Signals);
@NAMES = ("Hammer");

=head1 GT::Signals::Graphical::CandleSticks::Hammer

=head2 Overview

The Hammer Pattern is formed by a short body at the top of a long trail. Hammers must occur at the end of significant trends to have meaning.

Hammers indicate indecision in the direction of the trend. A black (solid) hammer which occurs at the end of an uptrend is called a Hanging Man. Thsi type of Hammer indicates the market's propensity to sell off sharply. However, one should wait for the next session to confirm the bearish mood (i.e., for the market to open below the close of the hammer). On the other hand, white (open) Hammers which occur at the end of downtrends show strength for a reversal to the upside, since the bulls are clearly bucking the downtrend to close near the open for the session.

=head2 Construction

A Hammer occurs when the high, open and close occur at roughly the same
price, but the low of the day is far below.

=head2 Representation

             ___     _|_            |
       |    |   |   |   |    ###   ###
---   ---   |___|   |___|    ###   ###
 |     |      |       |       |     |
 |     |      |       |       |     |
 |     |      |       |       |     |

 48    52     80      84      32    36
 
=head2 Links

http://www.equis.com/free/taaz/candlesticks.html

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
    my $hammer_name = $self->get_name(0);;

    return if ($calc->signals->is_available($self->get_name(0), $i));
    return if (! $self->check_dependencies($calc, $i));
    
    my $cndl_code = $calc->indicators->get($cndl_name, $i);

    if (($cndl_code eq 32) or ($cndl_code eq 48) or ($cndl_code eq 80) or
	($cndl_code eq 36) or ($cndl_code eq 52) or ($cndl_code eq 84)) {
	$calc->signals->set($hammer_name, $i, 1);
    } else { 
	$calc->signals->set($hammer_name, $i, 0);
    }
}    

1;
