<%args>
$detailed
$p
$db
</%args>
<%init>

use Finance::GeniusTrader::Prices;

# variables to hold HTML data
my @loop;
my $htmldata_positiontype;
my $htmldata_positionid;
my $htmldata_code;
my $htmldata_name;
my $htmldata_source;
my $htmldata_currentprice;
my $htmldata_return;
my $htmldata_profit;
my $htmldata_stopprice;
my $htmldata_stopreturn;
my $htmldata_stopprofit;


foreach my $position ($p->list_open_positions) {
    if ($position->is_long) {
      $htmldata_positiontype="Long";
    } else {
       $htmldata_positiontype="Short";
    }
 
   $htmldata_name = $db->get_name($position->code);
   $htmldata_positionid=$position->id;
   $htmldata_code=$position->code;
   
   if ($detailed and $position->source) { 
      $htmldata_source=$position->source;
   } else {
      $htmldata_source="<br>";
   }

   my @htmldata_orderlist;
   foreach my $order_temp ($position->list_detailed_orders) {

      my %text = (
         submission_date   => $order_temp->submission_date,
         order_type        => $order_temp->is_buy_order ? "Buy" : "Sell",
         quantity          => $order_temp->quantity,
         price             => sprintf("%.4f",$order_temp->price)
         );
 
      push(@htmldata_orderlist,\%text);
   }
   

   my $pstats = $position->stats($p);
   my $sstats = { %{$pstats} };
   my $prices;
   if (! $db->has_code($position->code)) {
      print "Code not available in database. No calculations done.\n\n";
      next;
   }
   eval {
       $prices = $db->get_last_prices($position->code, 1);
   };
   
   if ($@) {
      print "Error while retrieving prices. No calculations done.\n\n";
      next;
   }
   my $order = Finance::GeniusTrader::Portfolio::Order->new();
   $order->set_quantity($position->quantity);
   $order->set_type_limited();
   $order->set_price($prices->at($prices->count() - 1)->[$CLOSE]);
   if ($position->is_long) {
      $order->set_sell_order;
      $pstats->{'sold'} += $position->quantity * $order->price;
      $sstats->{'sold'} += $position->quantity * $position->stop if defined($position->stop);
   } else {
      $order->set_buy_order;
      $pstats->{'bought'} += $position->quantity * $order->price;
      $sstats->{'bought'} += $position->quantity * $position->stop if defined($position->stop);
   }
   $pstats->{'costs'} += $p->get_order_cost($order);
   $sstats->{'costs'} = $pstats->{'costs'};
   my $diff = $pstats->{'sold'} - $pstats->{'bought'} - $pstats->{'cost'};
   my $diff2 = $sstats->{'sold'} - $sstats->{'bought'} - $sstats->{'cost'};
   my $variation = 0;
   my $variation2 = 0;
   if ($position->is_long) {
      $variation = ($pstats->{'bought'} !=0) ? ($diff / $pstats->{'bought'}) : 0;
      $variation2 = ($sstats->{'bought'} !=0) ? ($diff2 / $sstats->{'bought'}) : 0;
   } else {
      $variation = ($pstats->{'sold'} !=0) ? ($diff / $pstats->{'sold'}) : 0;
      $variation2 = ($sstats->{'sold'} !=0) ? ($diff2 / $sstats->{'sold'}) : 0;
   }
   
   $htmldata_currentprice=sprintf("%.2f", $order->price);
   $htmldata_return = sprintf("%.2f%%",$variation * 100);
   $htmldata_profit = sprintf("%.0f",$diff);

   if (defined($position->stop)) { 
      $htmldata_stopprice=sprintf("%.2f", $position->stop);
      $htmldata_stopreturn=sprintf("%.2f%%", $variation2 * 100);
      $htmldata_stopprofit=sprintf("%.0f", $diff2);
   }
   
   # build the row data for the html template from all the data we have collected above 
   my %row = (
      positiontype  =>$htmldata_positiontype,
      positionid    =>$htmldata_positionid,
      code          =>$htmldata_code,
      name          =>$htmldata_name,
      source        =>$htmldata_source,
      currentprice  =>$htmldata_currentprice,
      return        =>$htmldata_return,
      profit        =>$htmldata_profit,
      stopprice     =>$htmldata_stopprice,
      stopreturn    =>$htmldata_stopreturn,
      stopprofit    =>$htmldata_stopprofit,
      orderlist     =>\@htmldata_orderlist
   );

   # now put this row onto our html data array
   push(@loop,\%row);
}

</%init>

<& portfolio_positions.mhtml, loop=>\@loop &>