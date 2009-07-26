package Finance::GeniusTrader::Graphics::DataSource;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

require Finance::GeniusTrader::Graphics::DataSource::Prices;
require Finance::GeniusTrader::Graphics::DataSource::Volume;
require Finance::GeniusTrader::Graphics::DataSource::Close;
require Finance::GeniusTrader::Graphics::DataSource::PricesColor;
require Finance::GeniusTrader::Graphics::DataSource::GenericIndicatorResults;
require Finance::GeniusTrader::Graphics::DataSource::SingleIndicator;
require Finance::GeniusTrader::Graphics::DataSource::Systems;
require Finance::GeniusTrader::Graphics::DataSource::PortfolioEvaluation;

=head1 Finance::GeniusTrader::Graphics::DataSource

A datasource if a source of data for a graphical object. The datas
are always indexed by an integer.

=head1 FUNCTION TO IMPLEMENT

Each real datasource has to implement a few functions :

=head2 Constructor : $ds->new(...)

A constructor for the datasource has the right to have parameters.
When constructed it should update the available range and set the
selected range to the available range.

=head2 $ds->get($index)

Return the data associated to the corresponding index.

=head2 $ds->is_available($index)

Tell if the data is available for the corresponding index.

=head2 $ds->update_value_range()

Update the minimum value and the maximum value.

=head1 GENERIC FUNCTIONS AVAILABLE

=head2 ($start, $end) = $ds->get_selected_range()

Return the range of selected data.

=cut
sub get_selected_range {
    my ($self) = @_;
    return ($self->{'selected_start'}, $self->{'selected_end'});
}

=head2 $ds->set_selected_range($start, $end)

Set the range of selected data.

=cut
sub set_selected_range {
    my ($self, $start, $end) = @_;
    $self->{'selected_start'} = $start;
    $self->{'selected_end'} = $end;
    $self->update_value_range();
}

=head2 ($start, $end) = $ds->get_available_range()

Return the range of available data.

=cut
sub get_available_range {
    my ($self) = @_;
    return ($self->{'available_start'}, $self->{'available_end'});
}

=head2 $ds->set_available_range($start, $end)

Set the range of available data.

=cut
sub set_available_range {
    my ($self, $start, $end) = @_;
    $self->{'available_start'} = $start;
    $self->{'available_end'} = $end;
}

=head2 ($min, $max) = $ds->get_value_range()

Return the minimum and the maximum of the values available within
the selected range.

=cut
sub get_value_range {
    my ($self) = @_;
    return ($self->{'min_value'}, $self->{'max_value'});
}

=head2 $ds->set_min_value($min)

Set the minimum value.

=cut
sub set_min_value {
    my ($self, $min) = @_;
    $self->{'min_value'} = $min;
}

=head2 $ds->set_max_value($max)

Set the maximum value.

=cut
sub set_max_value {
    my ($self, $max) = @_;
    $self->{'max_value'} = $max;
}

1;
