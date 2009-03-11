package GT::Graphics::Object::MultiPoly;

use strict;
use vars qw(@ISA);
@ISA = qw(GT::Graphics::Object);

use GT::Graphics::Object;
use GT::Graphics::Driver;
use GT::Graphics::Tools qw(:color);
use GT::Conf;

GT::Conf::default("Graphic::MultiPoly::Color", "red");

sub init {
    my ($self, @ds) = @_;
    $self->{"ds"} = \@ds;
    
    # Default values ...
    $self->{'fg_color'} = get_color(GT::Conf::get("Graphic::MultiPoly::Color"));
    $self->{filled} = 1;

}

sub display {
    my ($self, $driver, $picture) = @_;
    my $scale = $self->get_scale();
    my $zone = $self->{'zone'};
    my ($start, $end) = $self->{'source'}->get_selected_range();
    my $space = $scale->convert_to_x_coordinate($start + 1) -
	        $scale->convert_to_x_coordinate($start);

    # only $y_min and $y_max are significant
    my ($x_min, $y_min) = $scale->get_value_from_coordinate($start, 0);
    my ($x_max, $y_max) = $scale->get_value_from_coordinate($end, $zone->height-1);

    # these are coordinate values of $y_min and $y_max
    my $yc_min = $scale->convert_to_y_coordinate($y_min);
    my $yc_max = $scale->convert_to_y_coordinate($y_max);

    my ($first_pt, $second_pt);
    for(my $i = $start; $i <= $end; $i++)
    {
        next unless
            $self->{'source'}->is_available($i) && $self->{'source'}->get($i);

        my @realpoints;
        for (my $j = 0; $j < $#{$self->{ds}}+1; $j+=2) {
            my $p1 = ref $self->{ds}[$j] ? $self->{ds}[$j]->get($i) : $i;
            my $p2 = ref $self->{ds}[$j+1] ? $self->{ds}[$j+1]->get($i) : $i;
            push @realpoints, [ $p1, $p2 ];
        }
        push @realpoints, [$realpoints[0][0], $realpoints[0][1]];

        $self->{'points'} = \@realpoints;
        require GT::Graphics::Object::Polygon;
        GT::Graphics::Object::Polygon::display($self, $driver, $picture);
        local $self->{filled} = 0;
        local $self->{'fg_color'} = get_color('black');
        GT::Graphics::Object::Polygon::display($self, $driver, $picture);
    }
}

1;
