package GT::Indicators::Generic::ByName;

# Copyright 2000-2002 Raphaël Hertzog, Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("ByName[#*]");
@DEFAULT_ARGS = ("");

=head2 NAME

GT::Indicators::Generic::ByName - Alias to another indicator

=head2 DESCRIPTION

Sometimes when you create expressions to be passed as parameters
to other indicators you need to include a reference to a value
which is calculated by the indicator in which you are. But it you give
name of the current indicator you may have an infinite recursion
because of the dependencies.

This indicator can help you break that loop by using an indirection
level. This indicator is nothing more than an alias of a another value
calculated by another indicator. Just give as first parameter the name
of the value to use and you're done.

=cut

sub new {
    my ($type, $args, $key) = @_;
    my $class = ref($type) || $type;
    my $self = { };
    no strict "refs";
    $self->{'args'}->[0] = join(" ", @{$args});
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

    if ($indic->is_available($parname, $i)) {
	$indic->set($name, $i, $indic->get($parname, $i) );
	return;
    }
    #print "Failed to retrieve $parname for day $i.\n";
    $parname =~ s/\s+{/{/g;
    $parname =~ s/}\s+/}/g;
    #print "Trying instead $parname\n";
    if ($indic->is_available($parname, $i)) {
	$indic->set($name, $i, $indic->get($parname, $i) );
	return;
    }
    #print "Failed as well.\n";
}

1;
