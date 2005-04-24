package GT::Graphics::DataSource::Volume;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

@ISA = qw(GT::Graphics::DataSource);

use GT::Prices;
use GT::Graphics::DataSource;
use GT::Tools qw(:math);

=head1 GT::Graphics::DataSource::Volume

This datasource provides volume information.
It uses a GT::Prices object as a basis.

=head2 GT::Prices::DataSource::Volume->new($prices)

Create a new volume data source.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $prices = shift;
    
    my $self = { "prices" => $prices };
    
    bless $self, $class;

    $self->set_available_range(0, $prices->count() - 1);
    $self->set_selected_range($self->get_available_range());
    
    return $self;
}

sub is_available {
    my ($self, $index) = @_;
    if (($index >= 0) && ($index < $self->{'prices'}->count()))
    {
	return 1;
    }
    return 0;
}

sub get {
    my ($self, $index) = @_;
    return $self->{'prices'}->at($index)->[$VOLUME];
}

sub update_value_range {
    my ($self) = @_;
    my ($start, $end) = $self->get_selected_range();
    my ($min, $max);
    $min = $self->{'prices'}->at($start)->[$VOLUME];
    $max = $self->{'prices'}->at($start)->[$VOLUME];
    for(my $i = $start; $i <= $end; $i++) {
	$min = min($self->{'prices'}->at($i)->[$VOLUME], $min);
	$max = max($self->{'prices'}->at($i)->[$VOLUME], $max);
    }
    $self->set_min_value($min);
    $self->set_max_value($max);
}

1;
