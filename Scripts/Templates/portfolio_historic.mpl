<%args>
$detailed
$p
$db
</%args>
<%init>

# variables to hold HTML data
my @loop;
my $htmldata_positiontype;
my $htmldata_positionid;
my $htmldata_code;
my $htmldata_name;
my $htmldata_source;
my $htmldata_return;
my $htmldata_profit;

foreach my $position (@{$p->{'history'}}) {
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
   foreach my $order ($position->list_detailed_orders) {
      my %text = (
         submission_date   => $order->submission_date,
         order_type        => $order->is_buy_order ? "Buy" : "Sell",
         quantity          => $order->quantity,
         price             => sprintf("%.4f",$order->price)
         );
       push(@htmldata_orderlist,\%text);
   }
   
   if ($detailed) {
      my $pstats = $position->stats($p);
      my $diff = $pstats->{'sold'} - $pstats->{'bought'} 
   		- $pstats->{'cost'};
      my $variation = 0;
      
      if ($position->is_long) {
	      $variation = ($pstats->{'bought'} !=0) ? 
                       ($diff / $pstats->{'bought'}) : 0;
      } else {
	      $variation = ($pstats->{'sold'} !=0) ? 
		      ($diff / $pstats->{'sold'}) : 0;
      }

      $htmldata_return = sprintf("%.2f%%",$variation * 100);
      $htmldata_profit = sprintf("%.0f",$diff);
      
   }

   # build the row data for the html template from all the data we have collected above 
   my %row = (
     positiontype  =>$htmldata_positiontype,
     positionid    =>$htmldata_positionid,
     code          =>$htmldata_code,
     name          =>$htmldata_name,
     source        =>$htmldata_source,
     return        =>$htmldata_return,
     profit        =>$htmldata_profit,
     orderlist     =>\@htmldata_orderlist
   );

   # now put this row onto our html data array
   push(@loop,\%row);

}


</%init>

<& portfolio_historic.mhtml, loop=>\@loop &>