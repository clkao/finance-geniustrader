package GT::Graphics::DataSource::SingleIndicator;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

@ISA = qw(GT::Graphics::DataSource);

use GT::Eval;
use GT::CacheValues;
use GT::Graphics::DataSource;
use GT::Tools qw(:math);
use GT::Tools qw(extract_object_number);

=head1 GT::Graphics::DataSource::SingleIndicator

This datasource is a generic module to handle any information provided by an 
indicator.

We will return a serie of data based on a single generic indicator name, like
"Indicators::BOL/2".

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($calc, $desc) = @_;
    
    my @function = split(/\s+/, $desc);
    my $indicator = create_standard_object(@function);
    my $number = extract_object_number(@function);
    
    my $self = { 'calc' => $calc, 'indicator' => $indicator,
		 'number' => $number, 'calculated' => 1 };
    bless $self, $class;

    my $first = $indicator->days_required - 1;
    my $last = $calc->prices->count - 1;
    
    $self->set_available_range($first, $last);
    $self->set_selected_range($self->get_available_range());
    $self->{'calculated'} = 0;

    return $self;
}

sub calculate {
    my ($self, $force) = @_;
    $force = 0 if (! defined($force));
    if ($force && !$self->{'calculated'}) {
	$self->{'indicator'}->calculate_interval($self->{'calc'}, $self->get_selected_range());
    }
}

sub set_selected_range {
    my ($self, $start, $end) = @_;

    $self->{'selected_start'} = $start;
    $self->{'selected_end'} = $end;

    $self->calculate(1);
    $self->update_value_range();
}

sub is_available {
    my ($self, $index) = @_;
    my $calc = $self->{'calc'};
    my $indicator = $self->{'indicator'};
    my $number = $self->{'number'};
    my $name = $indicator->get_name($number);

    $self->calculate();
    
    return $calc->indicators->is_available($name, $index);
}

sub get {
    my ($self, $index) = @_;
    my $calc = $self->{'calc'};
    my $indicator = $self->{'indicator'};
    my $number = $self->{'number'};
    
    my $name = $indicator->get_name($number);
    if ($calc->indicators->is_available($name, $index)) {
	return $calc->indicators->get($name, $index);
    }
}

sub update_value_range {
    my ($self) = @_;
    my $calc = $self->{'calc'};
    my $indicator = $self->{'indicator'};
    my $number = $self->{'number'};
    my ($start, $end) = $self->get_selected_range();
    my ($min, $max);
    
    my $name = $indicator->get_name($number);

    for(my $i = $start; $i <= $end; $i++) {
	if ($calc->indicators->is_available($name, $i)) {
	    $min = $calc->indicators->get($name, $i) if (! defined($min));
	    $max = $calc->indicators->get($name, $i) if (! defined($max));
	    $min = min($calc->indicators->get($name, $i), $min);
	    $max = max($calc->indicators->get($name, $i), $max);
	}
    }
    $self->set_min_value($min);
    $self->set_max_value($max);
}

1;
