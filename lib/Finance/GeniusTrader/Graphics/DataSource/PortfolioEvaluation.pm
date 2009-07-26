package Finance::GeniusTrader::Graphics::DataSource::PortfolioEvaluation;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA);

@ISA = qw(Finance::GeniusTrader::Graphics::DataSource);

use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::CacheValues;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Graphics::DataSource;
use Finance::GeniusTrader::Tools qw(:math);
use Finance::GeniusTrader::Tools qw(extract_object_number);

=head1 Finance::GeniusTrader::Graphics::DataSource::PortfolioEvaluation

This datasource provides the evaluation of a portfolio.

=head2 Finance::GeniusTrader::Graphics::DataSource::PortfolioEvaluation->new($calc, $portfolio)

To create a new portfolio evalution datasource object, you need to give a
calculator and a portfolio as parameters.

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($calc, $portfolio) = @_;
    
    my $self = { 'calc' => $calc, 'portfolio' => $portfolio };
    
    bless $self, $class;

    my $first = 0;
    my $last = $calc->prices->count - 1;
    
    $self->set_available_range($first, $last);
    $self->set_selected_range($self->get_available_range());
    
    return $self;
}

sub is_available {
    my ($self, $index) = @_;
    my $calc = $self->{'calc'};
    my $portfolio = $self->{'portfolio'};

    return $portfolio->has_historic_evaluation($calc->prices->at($index)->[$DATE]);
}

sub get {
    my ($self, $index) = @_;
    my $calc = $self->{'calc'};
    my $portfolio = $self->{'portfolio'};

    my ($cash, $positions, $upcoming_gains_or_losses) =
    $portfolio->get_historic_evaluation($calc->prices->at($index)->[$DATE]);
    return ($cash + $positions + $upcoming_gains_or_losses);
}

sub update_value_range {
    my ($self) = @_;
    my $calc = $self->{'calc'};
    my $portfolio = $self->{'portfolio'};
    my ($start, $end) = $self->get_selected_range();
    my $min = $portfolio->current_cash + $portfolio->current_evaluation
                    + $portfolio->current_marged_gains;
    my $max = $min;
    
    for(my $i = $start; $i <= $end; $i++) {
	if ($portfolio->has_historic_evaluation($calc->prices->at($i)->[$DATE])) {
	    
	    my ($cash, $positions, $upcoming_gains_or_losses) =
	    $portfolio->get_historic_evaluation($calc->prices->at($i)->[$DATE]);
	    my $portfolio_value = $cash + $positions + $upcoming_gains_or_losses;
	    
	    $min = min($portfolio_value, $min);
	    $max = max($portfolio_value, $max);
        }
    }
    $self->set_min_value($min);
    $self->set_max_value($max)
}

1;
