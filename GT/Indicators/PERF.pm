package GT::Indicators::PERF;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@ISA @NAMES);

use GT::Indicators;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("PERF[#1]");

=head1 GT::Indicators::PERF

The performance indicator display a security's price performance from a reference day as a percentage. GT::Indicators::PERF->new($reference_day);

Example :
GT::Indicators::PERF->new(["2001-09-22"]);
GT::Indicators::PERF->new(["2001-09-22"], "VOLUME", $GET_VOLUME);

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my ($args, $key, $func) = @_;
    my $self = { 'args' => defined($args) ? $args : [] };
    
    # User defined function to get data or default with $GET_LAST
    if (defined($func)) {
        $self->{'_func'} = $func;
    } else {
        $self->{'_func'} = $GET_LAST;
	$key = 'LAST';
    }
    
    return manage_object(\@NAMES, $self, $class, $self->{'args'}, $key);
}

=head2 GT::Indicators::PERF::calculate($calc, $day)

=cut
sub calculate {
    my ($self, $calc, $i) = @_;
    my $reference = $self->{'args'}[0];
    my $getvalue = $self->{'_func'};
    my $indic = $calc->indicators;
    my $prices = $calc->prices;
    my $performance_name = $self->get_name(0);
    
    return if ($indic->is_available($performance_name, $i));
    
    # Make sure we already have a reference date
    $reference = $prices->at(0)->[$DATE] if (!$reference);
    my $item = $prices->date($reference);
    
    # Calculate the performance of a security from a reference day in percentage
    my $performance = (((&$getvalue($calc, $i) - &$getvalue($calc, $item)) / &$getvalue($calc, $item)) * 100);
    
    $indic->set($performance_name, $i, $performance);
}

1;
