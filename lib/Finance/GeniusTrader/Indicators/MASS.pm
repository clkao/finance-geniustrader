package GT::Indicators::MASS;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Indicators::EMA;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("MASS[#1,#2]");

=head1 GT::Indicators::MASS

=head2 Overview

The Mass Index was designed to identify trend reversals by measuring the narrowing and widening of the range between the high and low prices. As this range widens, the Mass Index increases; as the range narrows the Mass Index decreases.

The Mass Index was developed by Donald Dorsey.

=head2 Calculation

Mass Index = A-day sum of the ratio between the B-day EMA of (High - Low) and the B-day EMA of the B-day EMA of (High - Low)

=head2 Parameters

The standard Mass Index is calculated with : A = 25 and B = 9

=head2 Examples

GT::Indicators::MASS->new()
GT::Indicators::MASS->new([30, 14])

=head2 Links

http://www.equis.com/free/taaz/massindex.html
http://www.charthelp.com/reports/c21.htm

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args) = @_;
    my $self = { 'args' => defined($args) ? $args : [25, 9] };

    $args->[0] = 25 if (! defined($args->[0]));
    $args->[1] = 9 if (! defined($args->[1]));
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, "");
}

sub initialize {
    my $self = shift;
    
    # Initialize the fast moving average
    $self->{'fast_moving_average'} = GT::Indicators::EMA->new(
	[ $self->{'args'}[1] ], 
	"HIGH - LOW", 
	sub { 
	    $_[0]->prices->at($_[1])->[$HIGH] - 
	    $_[0]->prices->at($_[1])->[$LOW] 
	});

    # Initialize the slow moving average
    $self->{'slow_moving_average'} = GT::Indicators::EMA->new(
	[ $self->{'args'}[1] ], 
	"Slow Moving Average", 
	sub { 
	$_[0]->indicators->get($self->{'fast_moving_average'}->get_name, $_[1]) 
	});

    $self->add_indicator_dependency($self->{'fast_moving_average'},
			    $self->{'args'}[0] + $self->{'args'}[1]);
    $self->add_indicator_dependency($self->{'slow_moving_average'},
			    $self->{'args'}[0]);
}

=head2 GT::Indicators::MASS::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $fast_moving_average_name = $self->{'fast_moving_average'}->get_name;
    my $slow_moving_average_name = $self->{'slow_moving_average'}->get_name;
    my $mass_index_name = $self->get_name(0);
    my $sum_period = $self->{'args'}[0];
    my $ema_period = $self->{'args'}[1];
    my $mass_index_value = 0;
    
    return if ($indic->is_available($mass_index_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    for (my $n = 0; $n < $sum_period; $n++) {

	# Get fast and slow moving average values
	my $fast_moving_average_value = $indic->get($fast_moving_average_name, $i - $n);
        my $slow_moving_average_value = $indic->get($slow_moving_average_name, $i - $n);
    
	# Calculate the Mass Index (= sum of ($fast_moving_average / $slow_moving_average))
        $mass_index_value += ($fast_moving_average_value / $slow_moving_average_value);

    }

    # Return the results
    $indic->set($mass_index_name, $i, $mass_index_value);
}

1;
