package Finance::GeniusTrader::Graphics::Scale;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

=head1 Finance::GeniusTrader::Graphics::Scale

A scale converts local data (numbers) into coordinate ready to be displayed.

Can use linear scale or logarithmic ones.

linear :      X = a * x + b
logarithmic : X = ln(x - b + 1) * a

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;

    my $self = { "x_a" => 1, "x_b" => 0, "x_log" => 0,
		 "y_a" => 1, "y_b" => 0, "y_log" => 0
	       };
    
    return bless $self, $class;
}

=head2 $s->set_vertical_linear_mapping($y1, $y2, $ty1, $ty2)

Parameterize the scale to elaborate a mapping of [$y1,$y2] => [$ty1,$ty2]
on the vertical axis.

=cut
sub set_vertical_linear_mapping {
    my ($self, $y1, $y2, $ty1, $ty2) = @_;
    $self->{'y_a'} = ($y1 - $y2 != 0) ? ($ty1 - $ty2) / ($y1 - $y2) : 0;
    $self->{'y_b'} = $ty1 - $y1 * $self->{'y_a'};
    $self->{'y_log'} = 0;
}

=head2 $s->set_horizontal_linear_mapping($x1, $x2, $tx1, $tx2)

Parameterize the scale to elaborate a mapping of [$x1,$x2] => [$tx1,$tx2]
on the horizontal axis.

=cut
sub set_horizontal_linear_mapping {
    my ($self, $x1, $x2, $tx1, $tx2) = @_;
    $self->{'x_a'} = ($x1 - $x2 != 0) ? ($tx1 - $tx2) / ($x1 - $x2) : 0;
    $self->{'x_b'} = $tx1 - $x1 * $self->{'x_a'};
    $self->{'x_log'} = 0;
}

=head2 $s->set_vertical_logarithmic_mapping($y1, $y2, $ty1, $ty2)

Parameterize the scale to elaborate a logarithmic mapping of [$y1,$y2] =>
[$ty1,$ty2] on the vertical axis.

=cut
sub set_vertical_logarithmic_mapping {
    my ($self, $y1, $y2, $ty1, $ty2) = @_;
    $self->{'y_a'} = ($y2 - $y1 + 1 != 1 && $y2 - $y1 + 1 > 0) ? $ty2 / log($y2 - $y1 + 1) : 0;
#    $self->{'y_a'} = ($y2 - $y1 + 1 != 1 && $y2 - $y1 + 1 != 0) ? $ty2 / log($y2 - $y1 + 1) : 0;
    $self->{'y_b'} = $y1 - 1;
    $self->{'y_log'} = 1;
}

=head2 $s->set_horizontal_logarithmic_mapping($x1, $x2, $tx1, $tx2)

Parameterize the scale to elaborate a logarithmic mapping of [$x1,$x2] =>
[$tx1,$tx2] on the horizontal axis.

=cut
sub set_horizontal_logarithmic_mapping {
    my ($self, $x1, $x2, $tx1, $tx2) = @_;
    $self->{'x_a'} = (($x2 - $x1 + 1 != 1) && ($x2 - $x1 + 1 > 0)) ? $tx2 / log($x2 - $x1 + 1) : 0;
#    $self->{'x_a'} = (($x2 - $x1 + 1 != 1) && ($x2 - $x1 + 1 != 0)) ? $tx2 / log($x2 - $x1 + 1) : 0;
    $self->{'x_b'} = $x1 - 1;
    $self->{'x_log'} = 1;
}


=head2 ($nx, $ny) = $s->convert_to_coordinate($x, $y)

Returns the coordinate of the ($x, $y) point with the scale
modification applied.

=cut
sub convert_to_coordinate {
    my ($self, $x, $y) = @_;
    if ( ($self->{'y_log'}) && ($y <= $self->{'y_b'}) ) {
        $y = $self->{'y_b'} + 0.000001;
    }
    return ($self->{'x_log'} ? int($self->{'x_a'} * log($x - $self->{'x_b'})) :
			       int($self->{'x_a'} * $x + $self->{'x_b'}),
            $self->{'y_log'} ? int($self->{'y_a'} * log($y - $self->{'y_b'})) :
			       int($self->{'y_a'} * $y + $self->{'y_b'}));
}

=head2 $nx = $s->convert_to_x_coordinate($x)

Returns the X coordinate of the $X value with the scale
modification applied.

=cut
sub convert_to_x_coordinate {
    my ($self, $x) = @_;
    return ($self->{'x_log'} ? int($self->{'x_a'} * log($x - $self->{'x_b'})) :
			       int($self->{'x_a'} * $x + $self->{'x_b'}));
}

=head2 $ny = $s->convert_to_y_coordinate($y)

Returns the Y coordinate of the $y value with the scale
modification applied.

=cut
sub convert_to_y_coordinate {
    my ($self, $y) = @_;
    if ( ($self->{'y_log'}) && ($y <= $self->{'y_b'}) ) {
        $y = $self->{'y_b'} + 0.000001;
    }
    return ($self->{'y_log'} ? int($self->{'y_a'} * log($y - $self->{'y_b'})) :
			       int($self->{'y_a'} * $y + $self->{'y_b'}));
}

=head2 ($x, $y) = $s->get_value_from_coordinate($nx, $ny)

Returns the value corresponding to the given coordinate.

=cut
sub get_value_from_coordinate {
    my ($self, $x, $y) = @_;
    my ($x_value, $y_value) = (0, 0);
    if ($self->{'x_a'} != 0) {
	$x_value = $self->{'x_log'} ? exp($x / $self->{'x_a'}) + $self->{'x_b'} :
			       ($x - $self->{'x_b'}) / $self->{'x_a'};
    }
    if ($self->{'y_a'} != 0) {
	$y_value = $self->{'y_log'} ? exp($y / $self->{'y_a'}) + $self->{'y_b'} :
			       ($y - $self->{'y_b'}) / $self->{'y_a'};
    }
    return ($x_value, $y_value);
}

=head2 $s->copy_horizontal_scale($other)

=head2 $s->copy_vertical_scale($other)

Copy the horizontal/vertical scale defined in the $other scale object.

=cut
sub copy_horizontal_scale {
    my ($self, $other) = @_;
    $self->{'x_a'} = $other->{'x_a'};
    $self->{'x_b'} = $other->{'x_b'};
    $self->{'x_log'} = $other->{'x_log'};
}
sub copy_vertical_scale {
    my ($self, $other) = @_;
    $self->{'y_a'} = $other->{'y_a'};
    $self->{'y_b'} = $other->{'y_b'};
    $self->{'y_log'} = $other->{'y_log'};
}

1;
