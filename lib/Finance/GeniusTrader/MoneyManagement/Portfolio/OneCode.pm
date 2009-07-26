package Finance::GeniusTrader::MoneyManagement::Portfolio::OneCode;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use Finance::GeniusTrader::MoneyManagement;
use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::Analyzers::Process;
use Finance::GeniusTrader::Eval;

@NAMES = ("PF:OneCode[#1]");
@ISA = qw(Finance::GeniusTrader::MoneyManagement);

=head1 Finance::GeniusTrader::MoneyManagement::Basic

Basic and dumb money management rules (ie no rules).

=cut

sub new {
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ 10 ] };
 
    $args->[0] = 100 if (! defined($args->[0]));

    return manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}


sub manage_quantity {
  my ($self, $order, $i, $calc, $portfolio) = @_;

  foreach my $position ($portfolio->list_open_positions)
    {
      if ($position->code() eq $calc->code())
	{
	  return 0;
	}
    }


  if ( defined($order->{'quantity'}) )
    {
      print STDERR "Module OneCode returns: " . $order->{'quantity'} . "\n";
      return $order->{'quantity'};
    } else {
      return 0;
    }

  return 0;

}


1;
