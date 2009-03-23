package GT::ArgsTree;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw();

use GT::Eval;
use GT::Tools qw(:generic :conf);

#ALL#  use Log::Log4perl qw(:easy);

=head1 NAME

GT::ArgsTree - Represent the arguments of calculation objects (indics/signals/systems)

=head1 DESCRIPTION

Each calculation object can be parameterized with arguments.
But those arguments can themselves be calculation objects.
This is represented by a complex syntax that this module can understand
and use to create a tree of arguments.

=head1 SYNTAX

The argument list is a space separated list of arguments.
However when the argument is not a readable value but a
computable one, it should be given with a different syntax :

  { I::Indicator <indic_arg_list> }

=head1 AVAILABLE FUNCTIONS

=over

=item C<< GT::ArgsTree->new(@args) >>

Create an ArgsTree object for the given list of arguments. Instead of a
list you can give a string representation of all the arguments.

=cut
sub new {
    my ($type, @args) = @_;
    my $class = ref($type) || $type;
    my $self = [ { "full_name" => "", "name" => "" } ];
    bless $self, $class;
    $self->add_args(@args);
    return $self;
}

=item C<< $at->add_args(@args) >>

Process the list of arguments and adds them to the arguments tree.

=cut
sub add_args {
    my ($self, @args) = @_;

    my ($name, @objects) = parse_args(join(" ", @args));
    
    push @{$self}, @objects;
    if ($self->[0]{"full_name"}) {
	$self->[0]{"full_name"} .= " $name";
    } else {
	$self->[0]{"full_name"} = $name;
    }
    $self->create_objects(); # Update the associated objects
    return;
}

=item C<< $at->create_objects() >>

Creates the required objects to compute the various arguments.

=cut
sub create_objects {
    my ($self) = @_;
    for (my $i = 1; $i < scalar(@{$self}); $i++)
    {
	next if (ref($self->[$i]) !~ /ARRAY/);
	my @args = get_arg_names($self->[$i]);
	my $object = GT::Eval::create_standard_object($self->[$i][0]{"name"}, @args);
	my $number = extract_object_number($self->[$i][0]{"name"});
	$self->[$i][0]{"object"} = $object;
	$self->[$i][0]{"standard_name"} = "{" . GT::Eval::get_standard_name($object, 1, $number) . "}";
	$self->[$i][0]{"number"} = $number;
    }
    return;
}

=item C<< $at->is_constant($arg_number) >>

=item C<< $at->is_constant() >>

Return true if the corresponding argument is of constant value
(ie it doesn't have to be computed each time). If no argument is given,
then return true if all arguments are constant.

The first argument is numbered "1" (and not "0").

=cut
sub is_constant {
    my ($self, $n) = @_;
    my $res = 1;
    if (defined($n)) {
	#ERR#  ERROR  "Bad argument index in is_constant" if ( $n >= 1);
	$res = (ref($self->[$n]) =~ /ARRAY/) ? 0 : 1;
    } else {
	for (my $i = 1; $i < scalar(@{$self}); $i++)
	{
	    if (ref($self->[$i]) =~ /ARRAY/) {
		$res = 0;
		last;
	    }
	}
    }
    return $res;
}

=item C<< $at->get_arg_values($calc, $day) >>

=item C<< $at->get_arg_values($calc, $day, $n) >>

Return the (computed) value of the indicated argument. Returns the list
of values of all arguments if no parameter is given.

The first argument is numbered "1" (and not "0").

=cut
sub get_arg_values {
    my ($self, $calc, $day, $n) = @_;
    #ERR#  ERROR  "Bad calculator argument for get_arg_values" if ( ref($calc) =~ /GT::Calculator/);
    #ERR#  ERROR  "Bad day argument for get_arg_values" if ( $day =~ /^\d+$/);
    if (defined($n)) {
        my $indic = $calc->indicators;
	#ERR#  ERROR  "Bad argument index in get_arg_values" if ( $n >= 1 && $n < scalar(@{$self}));
	my $res = undef;
	if (ref($self->[$n]) =~ /ARRAY/) {
	    my $object = $self->[$n][0]{"object"};
	    my $number = $self->[$n][0]{"number"};
	    my $name = $object->get_name($number);
	    if (ref($object) =~ /GT::Indicators/) {
		$object->calculate($calc, $day) 
		  unless ($indic->is_available($name, $day));
		if ($indic->is_available($name, $day)) {
		    $res = $indic->get($name, $day);
		    return $res;
		}
	    } elsif (ref($object) =~ /GT::Signals/) {
		$object->detect($calc, $day)
		  unless ($calc->signals->is_available($name, $day));
		if ($calc->signals->is_available($name, $day)) {
		    $res = $calc->signals->get($name, $day);
		    return $res;
		}
	    } elsif (ref($object) =~ /GT::Analyzers/) {
		$object->calculate($calc, $day) 
		  unless ($indic->is_available($name, $day));
		if ($indic->is_available($name, $day)) {
		    $res = $indic->get($name, $day);
		    return $res;
		}
	    }
	} else {
	    $res = $self->[$n];
	}
	return $res;
    } else {
	my @res;
	for(my $i = 1; $i < scalar(@{$self}); $i++) {
	    push @res, get_arg_values($self, $calc, $day, $i);
	}
	return @res;
    }
    return;
}

=item C<< $at->get_arg_constant($n) >>

Return the constant value of the given argument. Make sure to check
that the argument is constant before otherwise it will die.

=cut
sub get_arg_constant {
    my ($self, $n) = @_;
    #ERR#  ERROR  "The argument number $n is not a constant value" if ( ref($self->[$n]) !~ /ARRAY/);
    #ERR#  ERROR  "Bad argument index in get_arg_constant" if ( $n >= 1 && $n < scalar(@{$self}));
    my $res = $self->[$n];
    return $res;
}

=item C<< $at->get_arg_object($n) >>

Return the associated object of the given argument. The object is something
able to compute the value of the argument. Make sure the argument is not a
constant otherwise it will die.

=cut
sub get_arg_object {
    my ($self, $n) = @_;
    #ERR#  ERROR  "The argument number $n has no associated object" if ( ref($self->[$n]) =~ /ARRAY/);
    #ERR#  ERROR  "Bad argument index in get_arg_object" if ( $n >= 1 && $n < scalar(@{$self}));
    my $res = $self->[$n][0]{"object"};
    return $res;
}

=item C<< $at->get_arg_names() >>

=item C<< $at->get_arg_names($n) >>

Return the name the indicated argument. Returns the list
of names of all arguments if no parameter is given.

The first argument is numbered "1" (and not "0").

=cut
sub get_arg_names {
    my ($self, $n) = @_;
    if (defined($n)) {
	#ERR#  ERROR  "Bad argument index in get_arg_names" if ( $n >= 1 && $n < scalar(@{$self}));
	my $res;
	if (ref($self->[$n]) =~ /ARRAY/) {
	    $res = $self->[$n][0]{"standard_name"} || $self->[$n][0]{"full_name"}
	} else {
	    $res = $self->[$n];
	}
	return $res;
    } else {
	my @res;
	for(my $i = 1; $i < scalar(@{$self}); $i++) {
	    push @res, get_arg_names($self, $i);
	}
	return @res;
    }
    return;
}

=item C<< $at->get_nb_args() >>

Return the number of arguments available.

=cut
sub get_nb_args {
    my ($self) = @_;
    my $res = scalar(@{$self}) - 1;
    return $res;
}

=item C<< my ($full_name, @args) = GT::ArgsTree::parse_args($args) >>

Parse the arguments in $args and return the parsed content in the form
of two arrays (list of arguments).

=cut
sub parse_args {
    
    my ($args) = @_;
    
    my (@objects) = ();
    my $full_name = "";

    my @l = split(/(\s*[\{\}]\s*|\"|\s+)/, $args);
    
    my $started = 0;
    my $in_quote = 0;
    my $string = "";
    
    # Remove leading/trailing empty elements
    while (scalar(@l) > 0) {
	if ($l[0] =~ m/^\s*$/) {
	    shift @l;
	} else {
	    last;
	}
    }
    while (scalar(@l) > 0) {
	if ($l[$#l] =~ m/^\s*$/) {
	    pop @l;
	} else {
	    last;
	}
    }
    # Treatment
    #DEB#  DEBUG  "Parse args : @l\n";
    while (scalar(@l)) {
	$_ = shift @l;
	#DEB#  DEBUG  "Treating part of argument list: « $_ »\n";
	if ($in_quote) {
	    $full_name .= $_;
	    if (/^"$/) { #end of string
		push @objects, $string;
		$in_quote = 0;
		#DEB#  DEBUG  "Full string argument: $string";
	    } else {
		$string .= $_;
	    }
	} else {
	    if (/^\s*{\s*$/) { # New complex subargument
		my $obj = shift @l;
		
		# Retrieve all arguments of this new object
		my $args = "";
		my $count = 1;
		while (scalar(@l)) {
		    $_ = shift @l;
		    $count++ if /^\s*{\s*$/;
		    $count-- if /^\s*}\s*$/;
		    last if $count == 0;
		    $args .= $_;
		}
		#WAR#  WARN  "Unmatched brackets in arg processing\n" if ( $count == 0);
		
		# Parse the arguments ///
		my ($n, @args) = parse_args($args);
		#DEB#  DEBUG  "Left to parse: @l\n";

		my (@names) = args_to_ascii(@args);
		
		# If the object is an alias, resolve it
		if ($obj =~ /^@(\S+)$/) {
		    my $def = resolve_object_alias(long_name($1), @names);
		    #DEB#  DEBUG  "Alias $1 maps to $def\n";
		    unshift @l, split(/(\s*[\{\}]\s*|\"|\s+)/, $def);
		    next;
		}

		# Add the new object
		$full_name .= " {$obj $n}";
		push @objects, [ { "full_name" => "{$obj $n}", "name" => $obj }, @args ];
		#DEB#  DEBUG  "New argument: $objects[$#objects]\n";
		#DEB#  DEBUG  "Current list of argument: @objects\n";
		
	    } elsif (/^\s*$/) { # New argument
		# Nothing
		$full_name .= " ";
	    } elsif (/^"$/) {
		$in_quote = 1;
		$string = "";
		$full_name .= '"';
	    } else { # New data
		if (/^@(\S+)$/) {
		    my $def = resolve_object_alias(long_name($1));
		    #DEB#  DEBUG  "Alias $1 maps to $def\n";
		    unshift @l, split(/(\s*[\{\}]\s*|\"|\s+)/, $def);
		    next;
		} else {
		    $full_name .= $_;
		    push @objects, $_;
		    #DEB#  DEBUG  "New argument: $_\n";
		    #DEB#  DEBUG  "Current list of argument: @objects\n";
		}
	    }
	}
    }
    
    return ($full_name, @objects);
}

=item C<< GT::ArgsTree::args_to_ascii(@args) >>

Return the ascii representation of all the parameters described in
@args.

=cut
sub args_to_ascii {
    my @args = @_;
    my @res = map {
	if (ref($_) =~ /ARRAY/) {
	    $_->[0]{'standard_name'}||$_->[0]{'full_name'}
	} else {
	    $_
	}
    } @args;
    return @res;
}

=item C<< $args->prepare($calc, $day) >>

Precalculate all possible values for the given day.

=cut
sub prepare {
    my ($self, $calc, $day) = @_;
    for(my $i = 1; $i < scalar(@{$self}); $i++) {
	next if $self->is_constant($i);
	my $object = $self->[$i][0]{"object"};
	if (ref($object) =~ /GT::Indicators/) {
	    $object->calculate($calc, $day);
	} elsif (ref($object) =~ /GT::Signals/) {
	    $object->detect($calc, $day);
	} elsif (ref($object) =~ /GT::Analyzers/) {
	    $object->calculate($calc, $day);
	}
    }
    return;
}

=item C<< $args->prepare_interval($calc, $first, $last) >>

Precalculate all possible values for the given interval.

=cut
sub prepare_interval {
    my ($self, $calc, $first, $last) = @_;
    for(my $i = 1; $i < scalar(@{$self}); $i++) {
	next if $self->is_constant($i);
	my $object = $self->[$i][0]{"object"};
	if (ref($object) =~ /GT::Indicators/) {
	    $object->calculate_interval($calc, $first, $last);
	} elsif (ref($object) =~ /GT::Signals/) {
	    $object->detect_interval($calc, $first, $last);
	} elsif (ref($object) =~ /GT::Analyzers/) {
	    $object->calculate_interval($calc, $first, $last);
	}
    }
    return;
}

=back

=cut
1;
