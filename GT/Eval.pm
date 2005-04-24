package GT::Eval;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@EXPORT @ISA);
#ALL#  use Log::Log4perl qw(:easy);

use GT::Conf;
use GT::ArgsTree;
use GT::Tools qw(:conf);

require Exporter;

@ISA = qw(Exporter);
@EXPORT = qw(create_standard_object create_db_object get_standard_name);

=head1 NAME

GT::Eval - Create unknown standard objects at run-time

=head1 DESCRIPTION 

This modules provides several functions to manipulate objects
based on their type name.

=over

=item C<< $object = create_standard_object($object_type, ...) >>

This will create an object of type $object_type. The following parameters
will be passed to the object at creation time.

=cut
sub create_standard_object {
    my ($type, @rawparams) = @_;
    
    $type = long_name($type);
    $type =~ s#/\d+##g;

    my ($name, @args) = GT::ArgsTree::parse_args(join(" ", @rawparams));
    if ($type =~ /^@(\S+)$/) {
	my $def = resolve_object_alias(long_name($1), @args);
	#DEB#  DEBUG  "Alias $1 maps to $def\n";
	if ($def =~ /^\s*{(.*)}\s*$/) {
	    $def = $1;
	}
	if ($def =~ /^\s*(\S+)\s*(.*)\s*$/) {
	    $type = long_name($1);
	    ($name, @args) = GT::ArgsTree::parse_args($2);
	}
    }
    
    my $object;
    my $eval = "use GT::$type;\n";
    $eval .= "\$object = GT::$type->new(";
    if (scalar(@args))
    {
	$eval .= "[" . join(",", map { if (/^\d+$/) { $_ } else { "'$_'" } } 
				 GT::ArgsTree::args_to_ascii(@args)) . "]";
    }
    $eval .= ");";
    #DEB#  DEBUG  "create_standard_object with: $eval";
    eval $eval;
    die $@ if ($@);

    return $object;
}

=item C<< create_db_object() >>

Return a GT::DB object created based on GT::Conf data. Thus GT::Conf::load()
should be called before this function. If DB::module doesn't exist in the
config, it tries to load the user configuration (supposing it has never been done
before).

=cut
our $db;
sub create_db_object {
    my $db_module = GT::Conf::get("DB::module");
    if (! defined($db_module)) {
	GT::Conf::load();
    }
    if (! defined($db)) {
	$db = create_standard_object("DB::" . GT::Conf::get("DB::module"));
    }
    return $db;
}

=item C<< get_standard_name($object, $shorten, $number) >>

Return the standard name of an object that can be later used to
create it again.

=cut
sub get_standard_name {
    my ($object, $shorten, $number) = @_;
    $shorten = 1 if (! defined($shorten));
    my $n = ref($object);
    $n =~ s/GT:://g;
    if ($shorten)
    {
	$n = short_name($n);
    }
    if (defined($number) && $number) {
	$n .= "/" . ($number + 1);
    }
    if (ref($object->{'args'}) =~ /GT::ArgsTree/) {
	$n .= " " . join(" ", $object->{'args'}->get_arg_names());
    } elsif (scalar(@{$object->{'args'}})) {
	$n .= " " . join(" ", @{$object->{'args'}});
    }
    return $n;
}

=pod 

=back

=cut
1;
