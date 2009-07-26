package GT::Graphics::DataSource::Systems;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

@ISA = qw(GT::Graphics::DataSource);

use GT::Eval;
use GT::CacheValues;
use GT::Prices;
use GT::Graphics::DataSource;
use GT::Tools qw(:math);
use GT::Tools qw(extract_object_number);

=head1 GT::Graphics::DataSource::Systems

This datasource is a generic module to handle any information provided by a 
system.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($calc, $system) = @_;
    
    my $self = { 'calc' => $calc, 'system' => $system };
    
    bless $self, $class;

    my $first = $system->days_required - 1;
    my $last = $calc->prices->count - 1;
    
    $self->set_available_range($first, $last);
    $self->set_selected_range($self->get_available_range());
    
    $system->precalculate_interval($calc, $first, $last);

    return $self;
}

sub is_available {
    my ($self, $index) = @_;
    my $calc = $self->{'calc'};
    my $system = $self->{'system'};
    
    return $system->check_dependencies($calc, $index);
}

sub get {
    my ($self, $index) = @_;
    my $calc = $self->{'calc'};
    my $system = $self->{'system'};
    
    if ($system->long_signal($calc, $index)) {
	return 1;
    } elsif ($system->short_signal($calc, $index)) {
	return -1;
    } else {
	return 0;
    }
}

sub update_value_range {
    my ($self) = @_;
}

1;
