package GT::Serializable;

# Copyright 2000-2003 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

#ALL#  use Log::Log4perl qw(:easy);
use XML::LibXML;
use Compress::Zlib;
use GT::Conf;

GT::Conf::default("Serializable::Compress", "1");

=head1 NAME

GT::Serializable - Add XML serialization functions to any object

=head1 DESCRIPTION

The functions available in GT::Serializable can add serialization
support to any simple perl object.

The various functions will serialize any hash, array or scalar
value blessed as an object.

Any object can be made serializable by adding GT::Serializable in
@ISA :

  our @ISA = qw(GT::Serializable);

All hash items whose names start with an underscore won't be
stored in the serialization process. 

=head1 RESTRICTIONS

Any reference to something else than a hash, array or scalar value will be
ignored (including function and file descriptor).

=head1 HOOKS

Once an object is created from scratch based on a serialization dump,
$object->init_after_load() is called so that the object has a chance to
restore things that may have not been stored (such as reference to
internal functions).

=head1 FUTURE

We may define later other hooks that will let the module personalize
the name of elements used to store the object in the XML file.

=head1 FUNCTIONS

=over

=item C<< $self->as_string() >>

=item C<< my $a = Module->create_from_string() >>

=item C<< $self->store("file" | \*FILE) >>

=item C<< my $a = Module->create_from_file("file" | \*FILE) >>

=back

=cut
sub as_string {
    my $self = shift;
    my $element = $self->_serialize_as_element($self);
    my $string = $element->toString();
    if ( GT::Conf::get("Serializable::Compress") == 1 ) {
        $string = Compress::Zlib::memGzip( $string ) ;
    }
    _unbind_node($element);
    return $string;
}

sub create_from_string {
    my ($class, $string) = @_;
    my $uc = Compress::Zlib::memGunzip($string);
    $string = $uc if ( defined($uc) );
    # init the doc from an XML string
    my $parser = XML::LibXML->new();
    my $xmlDoc = $parser->parse_string($string);
    my $ref = $class->_deserialize_from_element($xmlDoc->documentElement());
    _unbind_node($xmlDoc->documentElement());
    if (ref($ref) eq "") {
	bless $ref, $class;
    }
    if (ref($ref) ne $class) {
	warn "Object of type @{[ref($ref)]} has been created by deserialization of $class...";
    }
    return $ref;
}

sub store {
    my ($self, $file) = @_;

    my $handle;
    if (ref($file) eq "GLOB") {
	$handle = $file;
    } else {
	open(FILE, "> $file") || die "Can't open $file for writing: $!\n";
	$handle = \*FILE;
    }
    print $handle $self->as_string();
    if (ref($file) ne "GLOB") {
	close FILE;
    }
}

sub create_from_file {
    my ($class, $file) = @_;
    
    my $handle;
    if (ref($file) eq "GLOB") {
	$handle = $file;
    } else {
	open(FILE, "< $file") || die "Can't open $file for reading: $!\n";
	$handle = *FILE;
    }
    local $/ = undef;#"";
    my $string = <$handle>;
    if (ref($file) ne "GLOB") {
	close FILE;
    }
    return $class->create_from_string($string);
}

sub init_after_load {
    my ($self) = @_;
}


## PRIVATE FUNCTIONS

sub _unbind_node {
    my $node = shift;
    foreach my $child ($node->getChildnodes()) {
	_unbind_node($child);
	#$node->removeChild($child);
    }
    $node->unbindNode();
}

sub _serialize_as_element {
    my ($self, $item, $being_stored) = @_;
    # Beware, $item might be undef for valid reasons !
    $being_stored = { } if (! defined($being_stored));
    my $type = ref($item);
    my $element;
    if ($type ne "") {
	if (exists $being_stored->{"$item"}) {
	    # We have a loop in our structure
	    warn "Avoiding loop in XML serialize... break loop on $item ($type) by inserting void element.";
	    $element = XML::LibXML::Element->new("void");
	    return $element;
	}
	$being_stored->{"$item"} = 1;
    }
    if ($type eq "HASH") {
	$element = XML::LibXML::Element->new("hashref");
	foreach my $i (grep { ! /^_/ } sort keys %{$item}) {
	    my $child = $self->_serialize_as_element($item->{$i}, $being_stored);
	    $child->setAttribute("key", $i);
	    $element->appendChild($child);
	}
    } elsif ($type eq "ARRAY") {
	$element = XML::LibXML::Element->new("arrayref");
	foreach my $i (@{$item}) {
	    $element->appendChild($self->_serialize_as_element($i, $being_stored));
	}
    } elsif ($type eq "SCALAR") {
	$element = XML::LibXML::Element->new("scalarref");
	$element->appendChild($self->_serialize_as_element($$item, $being_stored));
    } elsif ($type eq "REF") {
	$element = XML::LibXML::Element->new("ref");
	$element->appendChild($self->_serialize_as_element($$item, $being_stored));
    } elsif ($type eq "CODE" or $type eq "GLOB" or $type eq "LVALUE") {
	$element = XML::LibXML::Element->new("void");
	# Forget it
    } elsif ($type ne "") {
	my $name = "$item";
	if ($name =~ /=HASH\(/) {
	    $element = XML::LibXML::Element->new("hashref");
	    $element->setAttribute("type", $type);
	    foreach my $i (grep { ! /^_/ } sort keys %{$item}) {
		my $child = $self->_serialize_as_element($item->{$i}, $being_stored);
		$child->setAttribute("key", $i);
		$element->appendChild($child);
	    }
	} elsif ($name =~ /=ARRAY\(/) {
	    $element = XML::LibXML::Element->new("arrayref");
	    $element->setAttribute("type", $type);
	    foreach my $i (@{$item}) {
		$element->appendChild($self->_serialize_as_element($i, $being_stored));
	    }
	} elsif ($name =~ /=SCALAR\(/) {
	    $element = XML::LibXML::Element->new("scalarref");
	    $element->setAttribute("type", $type);
	    $element->appendChild($self->_serialize_as_element($$item, $being_stored));
	}
    } elsif ($type eq "") {
	$element = XML::LibXML::Element->new("scalar");
	if (defined($item)) {
	    $element->setAttribute("value", "$item");
	} else {
	    $element->setAttribute("undef", "1");
	}
    }
    if ($type ne "") {
	delete $being_stored->{"$item"};
    }
    return $element;
}

sub _deserialize_from_element {
    my ($class, $element) = @_;
    my $type = $element->getName();
    my $value;
    my $obj_type = $element->getAttribute("type");
    if ($type =~ /^hashref/) {
	$value = {};
	foreach my $i ($element->getChildnodes()) {
	    next if ($i->getType() != 1);
	    $value->{$i->getAttribute("key")} = $class->_deserialize_from_element($i);
	}
    } elsif ($type =~ /^arrayref/) {
	$value = [];
	foreach my $i ($element->getChildnodes()) {
	    next if ($i->getType() != 1);
	    push @{$value}, $class->_deserialize_from_element($i);
	}
    } elsif ($type =~ /^scalarref/) {
	my $scalar;
	foreach my $i ($element->getChildnodes()) {
	    next if ($i->getType() != 1);
	    $scalar = $class->_deserialize_from_element($i);
	    last;
	}
	$value = \$scalar;
    } elsif ($type =~ /^ref/) {
	my $object;
	foreach my $i ($element->getChildnodes()) {
	    next if ($i->getType() != 1);
	    $object = $class->_deserialize_from_element($i);
	    last;
	}
	$value = \$object;
    } elsif ($type eq "scalar") {
	if ($element->hasAttribute("undef")) {
	    $value = undef;
	} else {
	    $value = $element->getAttribute("value");
	}
    } elsif ($type eq "void") {
	# nothing
    }
    if (defined($obj_type) && $obj_type) {
	bless $value, $obj_type;
	eval "require $obj_type";
	$value->init_after_load();
    }
    return $value;
}

1;
