package GT::Graphics::DataSource::GenericIndicatorResults;

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

=head1 GT::Graphics::DataSource::GenericIndicatorResults

This datasource is a generic module to handle any information provided by
an indicator.

=head2 Details

This module will return either a serie of single data or a serie of array.

If the input arguments contains a string like "Indicators::BOL/99", we
will assume that the user wants to have all data available form the
Bollinger indicator and we will return an array with all the data.

If the input arguments contains a string like "Indicators::BOL" (It's the
same than "Indicators::BOL/0"), "Indicators::BOL/1" (or / any number), we
will assume that the user only wants a serie of single data, which is in
our example the third serie (keep in mind that the first serie start at
zero).

We will either use only a single data serie or a all data available for
the calculation of the value range.

=head2 GT::Graphics::DataSource::GenericIndicatorResults->new($calc, $indicator_desc)

Create a new indicator data source.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($calc, $desc) = @_;
    
    my @function = split(/\s+/, $desc);
    my $indicator = create_standard_object(@function);
    my $number = extract_object_number(@function);
    if ($function[0] !~ m#/#) {
	$number = 0;
    }
    if ($function[0] =~ m#/99#) {
	$number = -1;
    }
    
    my $self = { 'calc' => $calc, 'indicator' => $indicator,
		 'number' => $number };
    bless $self, $class;

    my $first = $indicator->days_required - 1;
    my $last = $calc->prices->count - 1;
    
    $self->set_available_range($first, $last);
    $self->set_selected_range($self->get_available_range());
    
    $indicator->calculate_interval($calc, $first, $last);

    return $self;
}

sub is_available {
    my ($self, $index) = @_;
    my $calc = $self->{'calc'};
    my $indicator = $self->{'indicator'};
    my $number = $self->{'number'};
    my $name = ($number < 0) ? $indicator->get_name : $indicator->get_name($number);
    
    return $calc->indicators->is_available($name, $index);
}

sub get {
    my ($self, $index) = @_;
    my $calc = $self->{'calc'};
    my $indicator = $self->{'indicator'};
    my $number = $self->{'number'};
    my @results;
    
    if ($number < 0) {
	for(my $n = 0; $n < $indicator->get_nb_values; $n++) {
	    my $name = $indicator->get_name($n);
	    if ($calc->indicators->is_available($name, $index)) {
		$results[$n] = $calc->indicators->get($name, $index);
	    }
	}
	return @results;
    } else {
	my $name = $indicator->get_name($number);
	if ($calc->indicators->is_available($name, $index)) {
	    return $calc->indicators->get($name, $index);
	}
    }
}

sub update_value_range {
    my ($self) = @_;
    my $calc = $self->{'calc'};
    my $indicator = $self->{'indicator'};
    my $number = $self->{'number'};
    my ($start, $end) = $self->get_selected_range();
    my ($min, $max);
    
    if ($number < 0) {

	my $name = $indicator->get_name;
	$min = $calc->indicators->get($name, $start);
	$max = $calc->indicators->get($name, $start);

	for(my $i = $start; $i <= $end; $i++) {
	    for(my $n = 0; $n < $indicator->get_nb_values; $n++) {
		$name = $indicator->get_name($n);
		if ($calc->indicators->is_available($name, $i)) {
		    $min = min($calc->indicators->get($name, $i), $min);
		    $max = max($calc->indicators->get($name, $i), $max);
		}
	    }
	}
    } else {
	
	my $name = $indicator->get_name($number);
	$min = $calc->indicators->get($name, $start);
	$max = $calc->indicators->get($name, $start);

	for(my $i = $start; $i <= $end; $i++) {
	    if ($calc->indicators->is_available($name, $i)) {
		$min = min($calc->indicators->get($name, $i), $min);
		$max = max($calc->indicators->get($name, $i), $max);
	    }
	}
    }
    $self->set_min_value($min);
    $self->set_max_value($max);
}

1;
