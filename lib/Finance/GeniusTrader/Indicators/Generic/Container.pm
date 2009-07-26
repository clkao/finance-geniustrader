package GT::Indicators::Generic::Container;

# Copyright 2004 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;

@ISA = qw(GT::Indicators);
@NAMES = ("Container[#*]");

=head1 NAME

GT::Indicators::Generic::Container - Fake indicator which does nothing but acts as a data container

=head1 DESCRIPTION

This indicator can be used to store arbitrary series of data in particular
temporary values used during calculations of complicated indicators. If you
need to calculate the SMA of an expression, you can store the result of that
expression in that indicator.

All arguments passed serves only one purpose : differentiate the
various series of data stored. Care should be taken to ensure the
uniqueness of the indicator name, if there is a chance that several
instances of this indicator are active at the same time (e.g., when
used as the long and short signals of a system).


=cut
sub new {
    my ($type, $args, $key) = @_;
    my $class = ref($type) || $type;
    my $self = { };
    no strict "refs";
    $self->{'args'}->[0] = join(" ", @{$args});
    # Just to avoid problems created by adding of spaces by GT::ArgsTree
    # parsing ...
    $self->{'args'}->[0] =~ s/\s+{/{/g;
    $self->{'args'}->[0] =~ s/}\s+/}/g;
    return manage_object(\@{"$class\::NAMES"}, $self, $class, $self->{'args'}, $key);
}

sub initialize {
    my ($self) = @_;

}

sub calculate {
    my ($self, $calc, $i) = @_;
    
    # Always succeeds !
}
