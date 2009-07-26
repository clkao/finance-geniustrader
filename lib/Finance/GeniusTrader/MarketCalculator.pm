package Finance::GeniusTrader::MarketCalculator;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use Finance::GeniusTrader::CacheValues;
use Finance::GeniusTrader::MetaInfo;

=head1 NAME

Finance::GeniusTrader::MarketCalculator - Calculator-like for Markets

=head1 DESCRIPTION

THIS OBJECT IS NOT USED ANYWHERE AT THE PRESENT TIME

This is a facility object to ease the collaboration of
between Finance::GeniusTrader::List, Finance::GeniusTrader::CacheValues and Finance::GeniusTrader::MetaInfo

=over

=item C<< my $market = Finance::GeniusTrader::Markets->new($list [, $name]) >>

Create a new Finance::GeniusTrader::Markets object with $list used for calculations. The market is associated to market $name.

=item C<< $market->indices() >>

=item C<< $market->indicators() >>

=item C<< $market->signals() >>

=item C<< $market->metainfo() >>

Return the corresponding object that is part of Finance::GeniusTrader::Markets.

=item C<< $market->set_name($name) >>

Set market object name.

=item C<< $market->name() >>

Return market object name.

=back

=cut
sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $list = shift;
    my $name = shift || "";
    
    my $self = { '_list' => $list, 'name' => $name };
    $self->{'_indices'} = Finance::GeniusTrader::CacheValues->new();
    $self->{'_indicators'}  = Finance::GeniusTrader::CacheValues->new();
    $self->{'_signals'} = Finance::GeniusTrader::CacheValues->new();
    $self->{'_metainfo'} = Finance::GeniusTrader::MetaInfo->new();
    
    return bless $self, $class;
}

sub set_name {
    my ($self, $name) = @_;
    $self->{'name'} = $name;
}

sub name {
    return shift->{'name'};
}

sub list {
    return shift->{'_list'};
}

sub indices {
    return shift->{'_indices'};
}

sub indicators {
    return shift->{'_indicators'};
}

sub signals {
    return shift->{'_signals'};
}

sub metainfo {
    return shift->{'_metainfo'};
}

1;
