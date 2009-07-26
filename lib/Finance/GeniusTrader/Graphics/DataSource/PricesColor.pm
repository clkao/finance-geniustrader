package Finance::GeniusTrader::Graphics::DataSource::PricesColor;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

@ISA = qw(Finance::GeniusTrader::Graphics::DataSource);

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Graphics::DataSource;
use Finance::GeniusTrader::Graphics::Driver;
use Finance::GeniusTrader::Tools qw(:math);
use Finance::GeniusTrader::Graphics::Tools qw(:color);
use Finance::GeniusTrader::Conf;

Finance::GeniusTrader::Conf::default("Graphic::PricesColor::Up",    "green");
Finance::GeniusTrader::Conf::default("Graphic::PricesColor::Down",  "red");
Finance::GeniusTrader::Conf::default("Graphic::PricesColor::Equal", "dark grey");

=head1 Finance::GeniusTrader::Graphics::DataSource::PricesColor

This datasource provides a color depending on the prices movement.
Green when up, red when down, black when equal.

It uses a Finance::GeniusTrader::Prices object as a basis.

=head2 Finance::GeniusTrader::Prices::DataSource::PricesColor->new($prices)

Create a new prices color data source.

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $prices = shift;
    
    my $self = { "prices" => $prices, 
		 "color" => [ 
		 get_color(Finance::GeniusTrader::Conf::get("Graphic::PricesColor::Equal")),
		 get_color(Finance::GeniusTrader::Conf::get("Graphic::PricesColor::Down")),
		 get_color(Finance::GeniusTrader::Conf::get("Graphic::PricesColor::Up"))
			    ] 
		};
    
    bless $self, $class;

    $self->set_available_range(0, $prices->count() - 1);
    $self->set_selected_range($self->get_available_range());
    
    return $self;
}

=head2 $pc->set_{up,down,unchanged}_color($color)

Change the color returned for the up/down/unchanged days.

=cut
sub set_unchanged_color { $_[0]->{'color'}[0] = get_color($_[1]) }
sub set_down_color      { $_[0]->{'color'}[1] = get_color($_[1]) }
sub set_up_color        { $_[0]->{'color'}[2] = get_color($_[1]) }


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
    my $type = 0;
    if ($index >= 1) {	
	if ($self->{'prices'}->at($index)->[$LAST] eq $self->{'prices'}->at($index - 1)->[$LAST]) {
	    $type = 0;
	}
	if ($self->{'prices'}->at($index)->[$LAST] < $self->{'prices'}->at($index - 1)->[$LAST]) {
	    $type = 1;
	}
	if ($self->{'prices'}->at($index)->[$LAST] > $self->{'prices'}->at($index - 1)->[$LAST]) {
            $type = 2;
        }
    } else {
	if ($self->{'prices'}->at($index)->[$CLOSE] eq $self->{'prices'}->at($index)->[$OPEN]) {
	    $type = 0;	     
	}
	if ($self->{'prices'}->at($index)->[$CLOSE] < $self->{'prices'}->at($index)->[$OPEN]) {
	    $type = 1;
	}
	if ($self->{'prices'}->at($index)->[$CLOSE] > $self->{'prices'}->at($index)->[$OPEN]) {
            $type = 2;
        }
    }

    return $self->{'color'}[$type];
}

sub update_value_range {
    my ($self) = @_;
}

1;
