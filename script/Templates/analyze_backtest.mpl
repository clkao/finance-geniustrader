<%args>
$s
$l
%codes
$db
</%args>
<%init>

use Finance::GeniusTrader::Prices;
use Finance::GeniusTrader::BackTest::Spool;

# variables to hold HTML data
my @loop_by_code;
my @loop_by_system;

my $htmldata_code;
my $htmldata_name;
my $htmldata_systemname;

my $htmldata_returnper;
my $htmldata_return;
my $htmldata_maxdrawdown;
my $htmldata_numgains;
my $htmldata_numlosses;
my $htmldata_averagereturn;
my $htmldata_buyandhold;
  
my ($nb_gain, $nb_loss, $mean, $buyhold);

my $ana;
my $text;
   
####### Analysis by code
foreach my $code (sort keys %codes) {
   $nb_gain = $nb_loss = 0; $mean = 1; $buyhold = 0;
   my @systems = sort { 
    ($s->get_stats($b,$code)->[0] <=>
     $s->get_stats($a,$code)->[0]) ||
    ($s->get_stats($b,$code)->[1] <=>
     $s->get_stats($a,$code)->[1])
   }
   grep { 
	defined($s->get_stats($_,$code))
    } keys %{$l};
   
   next if (! scalar @systems);

   $htmldata_name = $db->get_name($code);
   $htmldata_code = $code;

   my @htmldata_returninfo;
   foreach (@systems) {
      $ana = $s->get_stats($_, $code);

      $buyhold = $ana->[3];
      if ($ana->[0] > 0) { $nb_gain++ } else { $nb_loss++ };
      $mean *= (1 + $ana->[0]);
      
      my $systemname = Finance::GeniusTrader::Report::_get_name($s, $_);
      
      my %text = (
         returnper      => sprintf("%.1f%%", $ana->[0] * 100),
         return         => sprintf("%.1f%%", $ana->[1] * 100),
         maxdrawdown    => sprintf("%.1f%%", $ana->[2] * 100),
         systemname     => $systemname
         );

      push(@htmldata_returninfo,\%text);

   }
   
   next if ($nb_loss + $nb_gain == 0);
   $mean = $mean ** (1 / ($nb_loss + $nb_gain));
   
   $htmldata_numgains = $nb_gain;
   $htmldata_numlosses  = $nb_loss;
   $htmldata_averagereturn = sprintf("%.1f%%",($mean -1) * 100);
   $htmldata_buyandhold = sprintf("%.1f%%", $buyhold * 100);
   
   # build the row data for the html template from all the data we have collected above 
   my %row = (
      code           =>$htmldata_code,
      name           =>$htmldata_name,
      numgains       =>$htmldata_numgains,
      numlosses      =>$htmldata_numlosses,
      averagereturn  =>$htmldata_averagereturn,
      buyandhold     =>$htmldata_buyandhold,
      returninfo     =>\@htmldata_returninfo      
   );

   # now put this row onto our html data array
   push(@loop_by_code,\%row);
}


####### Analysis by system
foreach my $sys (sort keys %{$l}) {
   $nb_gain = $nb_loss = 0; $mean = 1; $buyhold = 1;
   my @codes = sort { ($s->get_stats($sys,$b)->[0] <=> 
	    $s->get_stats($sys,$a)->[0]) || 
	   ($s->get_stats($sys,$b)->[1] <=> 
	    $s->get_stats($sys,$a)->[1])
      }
   grep { defined($s->get_stats($sys,$_)) } 
   @{$l->{$sys}};
   
   next if (! scalar @codes);

   $htmldata_systemname = Finance::GeniusTrader::Report::_get_name($s, $sys);

   my @htmldata_returninfo1;
   foreach (@codes) {
      $ana = $s->get_stats($sys, $_);
      if ($ana->[0] > 0) { $nb_gain++ } else { $nb_loss++ };
      $mean *= (1 + $ana->[0]);
      $buyhold *= (1 + $ana->[3]);

      my %text = (
         returnper      => sprintf("%.1f%%", $ana->[0] * 100),
         return         => sprintf("%.1f%%", $ana->[1] * 100),
         maxdrawdown    => sprintf("%.1f%%", $ana->[2] * 100),
         name           => $db->get_name($_),
         code           => $_
         );

      push(@htmldata_returninfo1,\%text);

   }

   next if ($nb_loss + $nb_gain == 0);
   $mean = $mean ** (1 / ($nb_loss + $nb_gain));
   $buyhold = $buyhold ** (1 / ($nb_loss + $nb_gain));
   
   $htmldata_numgains = $nb_gain;
   $htmldata_numlosses  = $nb_loss;
   $htmldata_averagereturn = sprintf("%.1f%%",($mean -1) * 100);
   $htmldata_buyandhold = sprintf("%.1f%%", ($buyhold - 1) * 100);
   
   # build the row data for the html template from all the data we have collected above 
   my %row = (
      systemname     =>$htmldata_systemname,
      numgains       =>$htmldata_numgains,
      numlosses      =>$htmldata_numlosses,
      averagereturn  =>$htmldata_averagereturn,
      buyandhold     =>$htmldata_buyandhold,
      returninfo     =>\@htmldata_returninfo1
      );

   # now put this row onto our html data array
   push(@loop_by_system,\%row);

}



</%init>

<& analyze_backtest.mhtml, loop_by_code=>\@loop_by_code, loop_by_system=>\@loop_by_system &>