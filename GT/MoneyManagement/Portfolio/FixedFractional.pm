package GT::MoneyManagement::Portfolio::FixedFractional;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;
use vars qw(@NAMES @ISA);

use GT::MoneyManagement;
use GT::Prices;
use Carp::Datum;
use GT::Analyzers::Process;
use GT::Eval;

@NAMES = ("PF:FixedFractional[#1]");
@ISA = qw(GT::MoneyManagement);

=head1 GT::MoneyManagement::Basic

Basic and dumb money management rules (ie no rules).

=cut

sub new {
    DFEATURE my $f, "new MoneyManagement";
    my $type = shift;
    my $class = ref($type) || $type;
    my $args = shift;
 
    my $self = { 'args' => defined($args) ? $args : [ 10 ] };
 
    $args->[0] = 100 if (! defined($args->[0]));

    return DVAL manage_object(\@NAMES, $self, $class, $self->{'args'}, '');
}


sub manage_quantity {
  DFEATURE my $f;
  my ($self, $order, $i, $calc, $portfolio) = @_;
  my $ratio = $self->{'args'}[0] / 100;
  
  my $cash = $portfolio->current_cash;
  my $positions = $portfolio->current_evaluation;
  my $upcoming_gains_or_losses = $portfolio->current_marged_gains;
  my $total_portfolio_value = $cash + $positions + $upcoming_gains_or_losses;
  my $current_marged_investment = $portfolio->current_marged_investment();
  my $portfolio_value = ( $cash - $current_marged_investment );
  

  #print STDERR "\nAnalysis at " . $calc->prices->at($i)->[5] . " / " . $calc->code() . "\n";
  #print STDERR "Portfolio : $cash, $positions, $upcoming_gains_or_losses, $current_marged_investment\n";

  foreach my $p ( $portfolio->list_pending_orders() ) {
    my $price = 0;
    $price = $p->{'price'} if (defined($p->{'price'}));
    if ( $price == 0 ) {
      foreach my $p2 ( @{$portfolio->{'parked-orders'}} ) {
	if ( $p2->[2]->code() eq $p->{'code'} ) {
	  $price = $p2->[2]->prices->at($p2->[1])->[$LAST];
	}
      }
    }
    my $quant = 0;
    $quant = $p->{'quantity'} if (defined($p->{'quantity'}));
    #print STDERR "    --> $portfolio_value -= $quant * $price;\n";
    $portfolio_value -= ($quant * $price);
  }

  #print STDERR "  ======> Resulting value: " . $portfolio_value . "\n";

  my $quant = 0;
  my $price = 0;
  if ($order->{'price'}) {
    $quant = int(($total_portfolio_value * $ratio) / $order->{'price'});
    $price = $order->{'price'};
  } else {
    $quant = int(($total_portfolio_value * $ratio) / $calc->prices->at($i)->[$LAST]);
    $price = $calc->prices->at($i)->[$LAST];
  }

  while ( $quant > 0 && $price * $quant > $portfolio_value ) {
    $quant--;
  }

  $quant = 0 if ( $quant < 0 );
  $quant = 0 if ( $quant * $price > ( $cash - $current_marged_investment ) );

  #print STDERR "  ======> Resulting quant.: " . $quant . " (Price: $price)\n";
  #print STDERR "FF:  $cash - $quant : $portfolio_value, $ratio\n";
  #print STDERR "FF2: $portfolio_value * $ratio / ".$calc->prices->at($i)->[$LAST]."\n";

  return $quant;

  return 0;
}


1;
