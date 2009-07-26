package Finance::GeniusTrader::Indicators::Generic::ByName;

# Copyright 2000-2002 Raphaël Hertzog, Oliver Bossert
# Copyright 2008 Thomas Weigert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id$

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use Finance::GeniusTrader::Indicators;
use Finance::GeniusTrader::ArgsTree;
use Finance::GeniusTrader::Prices;

@ISA = qw(Finance::GeniusTrader::Indicators);
@NAMES = ("ByName[#*]");
@DEFAULT_ARGS = ("");

=head2 NAME

Finance::GeniusTrader::Indicators::Generic::ByName - Alias to another indicator

=head2 DESCRIPTION

Sometimes, during the computation of an indicator, one needs to reference
the current value of a series that is being computed by this indicator.
If the current indicator is used explicity, an infinite recursion arises
due to the dependency mechanism.

This indicator resolves the recursion. This indicator is nothing more than
an alias of a series calculated by an indicator. Just give as first parameter
the name of the value to use.

This indicator is used when, during the calculation of an indicator,
an intermediate series wants to leverage another intermediate series
or an output value.

For example,

    $self->{'sma1'} = Finance::GeniusTrader::Indicators::SMA->new([ 
                      $self->{'args'}->get_arg_names(1),
                      $self->{'args'}->get_arg_names(2) ]);
    $self->{'sma2'} = Finance::GeniusTrader::Indicators::SMA->new([ 
                      $self->{'args'}->get_arg_names(1),
                      "{I:Generic:ByName "
                    . $self->{'sma1'}->get_name . "}" ]);

The first statement defines an intermediate series which smoothes the
second parameter. The second statement takes that series and applies 
smoothing again. Similarly, the following applies smoothing to
the first output value.

    $self->{'sma3'} = Finance::GeniusTrader::Indicators::SMA->new([
                      $self->{'args'}->get_arg_names(1),
                      "{I:Generic:ByName " . $self->get_name(0) . "}" ]);

Care has to be taken that I:Generic:ByName is in fact given the
name of an indicator, lest that series will not be found.  Note
that if the series is an indicator, the name of the series is the 
name of the selected return value. The get_name method will always 
retrieve the name of a series.

Remember that the parseable syntax does not yield a name.

=cut

sub new {
    my ($type, $pieces, $key) = @_;
    my $class = ref($type) || $type;
    my $self = { };
    no strict "refs";

    my @args = @{$pieces};
###    map {print "ByName new:$_\n"} @args;
    my $argstr = shift @args;
    foreach (@args) {
      if ($_ =~ /^\]/) {
        $argstr .= $_;
      } elsif ($_ =~ /^,$/) {
        $argstr .= $_;
      } else {
        $argstr .= " $_";
      }
    }
    $self->{'args'}->[0] = $argstr;
###    print "ByName: $self->{'args'}->[0]\n";
    return manage_object(\@{"$class\::NAMES"}, $self, $class, $self->{'args'}, $key);
}

sub initialize {
    my ($self) = @_;
}


sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $name = $self->get_name(0);

    my @pars = ();
    my $parname = $self->{'args'}->[0];
###    print "ByName($i): $parname = " . (($indic->is_available($parname, $i))?$indic->get($parname, $i):'') . "\n";

    $indic->set($name, $i, $indic->get($parname, $i))
     if ($indic->is_available($parname, $i));

}

1;
