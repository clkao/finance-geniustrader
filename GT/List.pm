package GT::List;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

=head1 NAME

GT::List - List of symbols (shares)

=head1 DESCRIPTION

This package provide some simple functions to work with a list of symbols.

=head2 Example

Create an empty GT::List object :
my $list = GT::List->new();

Load data from a list of symbol :
$list->load("/bourse/listes/us/nasdaq");

Add a symbol in a list :
$list->add("GeniusTrader");

Remove a symbol in a list :
$list->remove("GeniusTrader");

Save list in a file :
$list->save("/bourse/listes/us/nasdaq");

Find how many symbols are in a list :
$list->count();

Get symbol number $i :
$list->get($i);

=head2 Functions

=over

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { 'symbol' => [], 'count' => 0 };
    return bless $self, $class;
}

=item C<< $list->get($i) >>

Get symbol number $i.

=cut
sub get {
    my ($self, $i) = @_;
    return $self->{'symbol'}[$i];
}

=item C<< $list->add("symbol") >>

Add a symbol in a list.

=cut
sub add {
    my ($self, $symbol) = @_;
    push @{$self->{'symbol'}}, $symbol;
    $self->{'count'} += 1;
}

=item C<< $list->remove($i) >>

Remove the symbol number $i.

=cut
sub remove {
    my ($self, $i) = @_;

    for (my $n = $i; $n < $self->count() - 1; $n++) {
	$self->{'symbol'}[$n] = $self->{'symbol'}[$n + 1];
    }
    delete $self->{'symbol'}[$self->count() - 1];
    $self->{'count'} -= 1;
}

=item C<< $list->count() >>

Find how many symbols are in the list.

=cut
sub count {
    return shift->{'count'};
}

=item C<< $list->load("list_of_symbol.txt") >>

Load data from a list of symbol.

=cut
sub load {
    my ($self, $file) = @_;
    open(FILE, "<$file") || die "Can't open $file: $!\n";
    $self->{'symbol'} = [];
    while (defined($_=<FILE>))
    {
	chomp;
	$self->add($_);
    }
    close FILE;
}

=item C<< $list->save("list_of_symbol.txt") >>

Save list in a file.

=cut
sub save {
    my ($self, $file) = @_;
    open(FILE, ">$file") || die "Can't write in $file: $!\n";
    foreach (@{$self->{'symbol'}})
    {
	print FILE "$_\n";
    }
    close FILE;
}

=pod

=back

=cut
1;
