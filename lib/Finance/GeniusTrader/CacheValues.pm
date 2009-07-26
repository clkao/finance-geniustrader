package GT::CacheValues;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

=head1 NAME

GT::CacheValues - Cache the computed values (of indic/signals) for a single share

=head1 DESCRIPTION 

This object is designed to be associated with a GT::Prices object.
It may contain the computed value of some indicators corresponding
to the GT::Prices object.

=over

=item C<< my $cache = GT::CacheValues->new; >>

Create a new GT::CacheValues that will contain computed values of
some indicators or signals.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $self = { 'values'    => {} };

    return bless $self, $class;
}

=item C<< $cache->get($name, $i) >>

Return the value of the indicator $name for the day $i.

=cut
sub get {
    my ($self, $name, $i) = @_;
    
    if (defined($i)) {
	return $self->{'values'}{$name}[$i];
    } else {
	return $self->{'values'}{$name};
    }
}

=item C<< $cache->set($name, $i, $value) >>

Store the computed value $value of indicator $name for the day $i.

=cut
sub set {
    my ($self, $name, $i, $val) = @_;
    
    $self->{'values'}{$name}[$i] = $val;
}

=item C<< $cache->is_available($name, $i) >>

=item C<< $cache->is_available_interval($name, $first, $last) >>

Check if the value of indicator $name is available for day $i.

=cut
sub is_available {
    my ($self, $name, $i) = @_;

    return defined($self->{'values'}{$name}[$i]) ? 1 : 0;
}
sub is_available_interval {
    my ($self, $name, $first, $last) = @_;

    for (my $i = $first; $i <= $last; $i++)
    {
	if (! defined($self->{'values'}{$name}[$i]))
	{
	    return 0;
	}
    }
    return 1;
}

=pod

=back

=cut
1;
