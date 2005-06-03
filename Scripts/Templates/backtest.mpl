<%args>
$analysis
$sys_manager
$pf_manager
$verbose
</%args>
<%init>
    my $a = $analysis->{'real'};
    my $p = $analysis->{'portfolio'};

    # variables to hold HTML data
    my @loop;
    my $htmldata_tradenum;
    my $htmldata_code;
    my $htmldata_type;
    my $htmldata_source;
    my $htmldata_shares;
    my $htmldata_entrydate;
    my $htmldata_entryprice;
    my $htmldata_exitdate;
    my $htmldata_exitprice;
    my $htmldata_return;
    my $htmldata_duration;
    
    foreach my $position (@{$p->{'history'}})
    {
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
	my $className = ($variation > 0 ) ? "up" : "down";

	$htmldata_tradenum=$position->id;
	$htmldata_code=$position->code;

	if ($position->is_long)
	{
	    $htmldata_type="Long";
	} else {
	    $htmldata_type="Short";
	}
	$htmldata_source=$position->source;

	my $n = 0;
	my ($start_date, $start_price, $end_date, $end_price);
	foreach my $order ($position->list_detailed_orders)
	{
	   if ($n == 0)
	   {
		$htmldata_shares=$order->quantity;
		$start_date = $order->submission_date;
		$start_price = $order->price;
	   }
	   else
	   {
		$end_date = $order->submission_date;
		$end_price = $order->price;
	   }
	   $n++;
	}
	my $timeframe = 70;
	if (defined($position->timeframe)) {
	    $timeframe = $position->timeframe;
	}
	$htmldata_duration = (GT::DateTime::map_date_to_time($timeframe, $end_date) - GT::DateTime::map_date_to_time($timeframe, $start_date)) / 86400;
	
   $htmldata_entrydate=$start_date;
   $htmldata_entryprice=sprintf("%.4f", $start_price);
   $htmldata_exitdate=$end_date;
   $htmldata_exitprice=sprintf("%.4f", $end_price);
	$htmldata_return=sprintf("%.2f%%", $variation * 100);
   
   # build the row data for the html template from all the data we have collected above 
   my %row = (
      className  =>$className,
      tradenum   =>$htmldata_tradenum,
      code       =>$htmldata_code,
      type       =>$htmldata_type,
      source     =>$htmldata_source,
      shares     =>$htmldata_shares,
      entrydate  =>$htmldata_entrydate,
      entryprice =>$htmldata_entryprice,
      exitdate   =>$htmldata_exitdate,
      exitprice  =>$htmldata_exitprice,
      return     =>$htmldata_return,
      duration   =>$htmldata_duration
   );
   # now put this row onto our html data array
   push(@loop,\%row);

    }

    my %v;
    $v{'performance1'}	= sprintf("%.0f%%", $a->{'performance'} * 100);
    $v{'performance2'}	= sprintf("%.1f%%", $a->{'std_performance'} * 100);
    $v{'buyhold1'}	= sprintf("%.1f%%", $a->{'buyandhold'} * 100);
    $v{'buyhold2'}	= sprintf("%.1f%%", $a->{'std_buyandhold'} * 100);
    $v{'timeframe'}	= $a->{'std_timeframe'};
    $v{'maxdrawdown'}	= sprintf("%.1f%%", $a->{'max_draw_down'} * 100);
    $v{'bh_maxdrawdown'}= sprintf("%.1f%%", $a->{'buyandhold_max_draw_down'});
    $v{'bestperformance'}= sprintf("%.0f%%", $a->{'max_performance'} * 100);
    $v{'worstperformance'}= sprintf("%.1f%%", $a->{'min_performance'} * 100);
    $v{'netgain'}	= sprintf("%.2f", $a->{'global_gain'});
    $v{'grossgain'}	= sprintf("%.2f", $a->{'gross_gain'});
    $v{'nbtrades'}	= $a->{'nb_gain'} + $a->{'nb_loss'};
    $v{'nbtradesavg'}	= sprintf("%.2f", ($a->{'nb_gain'} + $a->{'nb_loss'}) / $a->{'duration'});
    $v{'nbgain'}	= $a->{'nb_gain'};
    $v{'nblosses'}	= $a->{'nb_loss'};
    $v{'winratio'}	= sprintf("%.1f%%", $a->{'win_loss_ratio'} * 100);
    $v{'maxconsecwin'}	= $a->{'max_consecutive_winner'};
    $v{'maxconsecloss'}	= $a->{'max_consecutive_loser'};
    $v{'expectancy'}	= sprintf("%.2f", $a->{'expectancy'});
    $v{'avggain'}	= sprintf("%.2f%%", $a->{'average_gain'} * 100);
    $v{'avgloss'}	= sprintf("%.2f%%", $a->{'average_loss'} * 100);
    $v{'avgperformance'}= sprintf("%.2f%%", $a->{'average_performance'} * 100);
    $v{'biggestgain'}	= sprintf("%.2f%%", $a->{'biggest_gain'} * 100);
    $v{'biggestloss'}	= sprintf("%.2f%%", $a->{'biggest_loss'} * 100);
    $v{'profictfactor'}	= sprintf("%.2f", $a->{'profit_factor'});
    $v{'sumgains'}	= sprintf("%.2f", $a->{'sum_of_gain'});
    $v{'sumlosses'}	= sprintf("%.2f", $a->{'sum_of_loss'});
    $v{'riskruin'}	= sprintf("%.1f%%", $a->{'risk_of_ruin'} * 100);

    $v{'sys'}		= $sys_manager->get_name;
    $v{'pf'}		= $pf_manager->get_name;
    $v{'first_date'}	= $a->{'first_date'}; 
    $v{'last_date'}	= $a->{'last_date'};
    $v{'verbose'}	= $verbose;
</%init>

<& backtest.mhtml, loop=>\@loop, v=>\%v &>