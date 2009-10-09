package Finance::GeniusTrader::Indicators::Hour;

# Standards-Version: 1.0 

use strict;
use vars qw(@ISA @NAMES);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Eval;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("Hour");

sub initialize {
    my $self = shift;
}

sub calculate {
    my ($self, $calc, $i) = @_;

    return if ($calc->indicators->is_available($self->get_name, $i));
    Carp::confess if $i < 0;
    return if $i<0;
    my $indic = $calc->indicators;
    my ($hh, $mm) = $calc->prices->at($i)->[$DATE] =~ m/ (\d\d):(\d\d)/;
    $indic->set($self->get_name, $i, $hh*100+$mm);
}

1;
