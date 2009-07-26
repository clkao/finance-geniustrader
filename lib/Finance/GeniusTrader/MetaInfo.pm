package Finance::GeniusTrader::MetaInfo;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

use XML::LibXML;

=head1 NAME

Finance::GeniusTrader::MetaInfo - keep various meta informations

=head1 DESCRIPTION

=head2 Goal

This object is used to gather meta informations of different kinds
applying to various objects (state of a trading system, history of order,
support & resistance of prices, top & bottom prices on a period,
lines drawn on a graph, ...). It stores various informations in an
internal XML structure that can be stored in a file and reloaded later.

Informations are stored on a key/value basis. Key is a path in an
XML DOM tree (/ is the separator like for xpath expressions). Several
values can be stored in a single key if you use attributes
to distinguish them.

=head2 API

=over 

=item C<< my $info = Finance::GeniusTrader::MetaInfo->new; >>

Create a new empty Finance::GeniusTrader::MetaInfo object.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = {};

    $self->{'_parser'} = XML::LibXML->new();

    return bless $self, $class;
}

=item C<< $info->set($key, $value, { "attrname" => "attrvalue" }); >>

Stores $value corresponding to $key with an attribute "attrname" (whose
value is "attrvalue"). The third parameter is optional if you don't need
attributes for this key.

If the key already existed, then the value is replaced.

=cut
sub set {
    my ($self, $key, $value, $attr) = @_;

    # If the document hasn't been created (aka loaded), create it
    if (!defined($self->{'doc'}))
    {
	$self->{'doc'} = XML::LibXML::Document->new("1.0", "ISO-8859-1");
	$self->{'doc'}->setDocumentElement(
		$self->{'doc'}->createElement('metainfo'));
    }

    # Split the key in successive element names to lookup
    # The last one is treated apart
    my @elts = split("/", $key);
    my $last = $elts[scalar(@elts) - 1];
    delete $elts[scalar(@elts) - 1];

    my $elt = $self->{'doc'}->getDocumentElement;
    my @list;
    # Browse the tree and build nodes when needed
    foreach (@elts) {
	if (scalar(@list = $elt->getElementsByTagName($_))) {
	    $elt = $list[0];
	} else {
	    $elt->appendChild($self->{'doc'}->createElement($_));
	    $elt = $elt->lastChild;
	}
    }
    # Create the xpath expression to find a node corresponding to the one
    # that we'll add, so that we can replace it
    my $xpath = _build_xpath_expr($last, $attr);
    # Create the new node
    my $node = $self->{'doc'}->createElement($last);
    if (defined($attr)) {
	foreach (keys %{$attr}) {
	    $node->setAttribute($_, $attr->{$_});
	}
    }
    $node->appendText($value);
    # Add the new node (eventually remove the old one)
    if (scalar(@list = $elt->findnodes($xpath))) {
	$elt->insertBefore($node, $list[0]);
	$list[0]->unbindNode();
    } else {
	$elt->appendChild($node);
	$elt->appendTextNode("\n\n");
    }
}

=item C<< $info->get($key, { "attrname" => "attrvalue" }); >>

Get the value corresponding the $key and the attributes indicated in the
second optional argument.

=cut
sub get {
    my ($self, $key, $attr) = @_;

    # Stop if we have no document
    return undef if (! defined($self->{'doc'}));
    
    # Build the xpath expression 
    $key = _build_xpath_expr($key, $attr);
    
    # Find the corresponding node
    my @elt = $self->{'doc'}->getDocumentElement()->findnodes($key);
    # Stop if no node has been found
    return undef if (! scalar(@elt));
    # Conver the node list in a list of values
    my @data;
    foreach (@elt)
    {
	push @data, $_->firstChild->nodeValue;
    }
    # Return either the first value or all depending on the context
    if (scalar(@data) == 0) {
	return undef;
    } elsif (scalar(@data) >= 1) {
	return wantarray ? @data : $data[0];
    }
}

=item C<< my @list = $info->list($key, { "attrname" => "attrvalue" }); >>

List all the set of attributes available for elements corresponding
to the $key. You can eventually restrict the list to a subset og them
by specifying one or more attributes.

Each element of @list is a hash describing the attributes. If you want
the value of that node you have to use $info->get(...).

=cut
sub list {
    my ($self, $key, $attr) = @_;
    
    # Stop if we have no document
    return if (! defined($self->{'doc'}));
    
    # Build the xpath expression to find the nodes
    $key = _build_xpath_expr($key, $attr);

    # Find the corresponding nodes and return their attributes
    my @list;
    foreach my $node ($self->{'doc'}->getDocumentElement()->findnodes($key))
    {
	my $attributes = {};
	foreach ($node->attributes)
	{
	    $attributes->{$_->nodeName} = $_->nodeValue;
	}
	push @list, $attributes;
    }
    return @list;
}
    
=item C<< $info->load("/path/to/file.xml") >>

Load the XML file as MetaInfo object.

=cut
sub load {
    my ($self, $file) = @_;
    
    $self->{'filename'} = $file;
    $self->{'doc'} = $self->{'_parser'}->parse_file($file);
}

=item C<< $info->save("/path/to/file.xml") >>

Save the current Finance::GeniusTrader::MetaInfo object in the given XML file. All values
previously set can be reloaded later with $info->load(...).

=cut
sub save {
    my ($self, $file) = @_;

    if (defined($file)) {
	$self->{'filename'} = $file;
    }
    open (XMLFILE, "> $self->{'filename'}")
      || die "Can't open $self->{'filename'} for writing: $!\n";
    print XMLFILE $self->{'doc'}->toString;
    close XMLFILE;
}

=item C<< $info->dump >>

Output the current internal XML file to the standard output. Useful
for debug purposes.

=cut
sub dump {
    my ($self) = @_;
    print $self->{'doc'}->toString;
}

# Private helper functions
sub _build_xpath_expr {
    my ($key, $attr) = @_;
    
    # Transform the key in a xpath expression to find the good node
    if (defined($attr))
    {
	$key .= "[";
	$key .= join " and ", map { "\@$_='$attr->{$_}'" } keys %{$attr};
	$key .= "]";
    }    
    return $key;
}

=pod

=back

=cut
1;
