<%args>
 $proc
</%args>
<%init>
 use lib '..';
 use lib '../..';
 use GT::Analyzers::Process;

# my $proc = shift;

my $nb = $proc->calc("{A:NB}");
my @long = $proc->calc_array("{A:Long}");
my @open_date = $proc->calc_array("{A:OpenDate}");
my @close_date = $proc->calc_array("{A:CloseDate}");
my @open_pr = $proc->calc_array("{A:OpenPrice}");
my @close_pr = $proc->calc_array("{A:ClosePrice}");
my @quant = $proc->calc_array("{A:Quantity}");
</%init>

Analysis of <% print "" . $proc->{'pf'}->{'name'} %>

## Global analysis (each position is 10keuros, value of portfolio)
Analysis of the portfolio (<% $proc->{'calc'}->prices->at($proc->{'first'})->[5] %> / <% $proc->{'calc'}->prices->at($proc->{'last'})->[5] %>) :
-----------------------------------------------------
% my $performance = sprintf("%7.2f", 100*$proc->calc("{A:SumPerformance}") );
% my $performance_y =  sprintf("%5.2f", 100*$proc->calc("{A:StdTime {A:SumPerformance}}") );
% my $bh =  sprintf("%7.2f", 100*$proc->calc("{A:BuyAndHold}") );
% my $bh_y =  sprintf("%5.2f", 100*$proc->calc("{A:StdTime {A:BuyAndHold}}") );
Performance :     <% $performance %>% (<% $performance_y %>%)  Buy & Hold :<% $bh %>% (<% $bh_y %>%) () => by year
%
% my $maxdd = sprintf("%7.2f", 100*$proc->calc("{A:Min {A:DrawDown}}") );
% my $bhdd =  sprintf("%7.2f", $proc->calc("{I:MaxDrawDown}") );
MaxDrawDown :     <% $maxdd%>%   B&H MaxDrawDown :   <% $bhdd %>%
%
% my $bestperf = sprintf("%7.2f", 100*$proc->calc("{A:Max {A:Performance {A:Accumulate {A:NetGain}} {A:InitSum}}}") );
% my $worstperf = sprintf("%7.2f", 100*$proc->calc("{A:Min {A:Performance {A:Accumulate {A:NetGain}} {A:InitSum}}}") );
Best performance :<% $bestperf %>%   Worst performance : <% $worstperf %>%
%
% my $ngain = sprintf ("%14.2f", $proc->calc("{A:Sum {A:NetGain}}"));
% my $nggross = sprintf ("%12.2f", ($proc->calc("{A:Sum {A:Costs}}")+$proc->calc("{A:Sum {A:NetGain}}")));
Net gain : <% $ngain %>    Gross gain :   <% $nggross %>

Trades statistics :
% my $nbg = sprintf("%5d", $proc->calc("{A:Sum {A:IsGain}}"));
% my $nbl = sprintf("%5d", $proc->calc("{A:Sum {A:IsLoss}}"));
% my $rat = sprintf("%7.2f", 100*$proc->calc("{A:WinRatio}"));
% #my $rat = ( $nbg + $nbl != 0) ? 100 * $nbg / ( $nbg + $nbl ) : 0;
Number of gains :   <% $nbg %>  Number of losses :   <% $nbl %>  Win. ratio : <% $rat %>%
%
% my $maxgaincons = sprintf("%5d", $proc->calc("{A:Consec {A:IsGain}}"));
% my $maxlosscons = sprintf("%5d", $proc->calc("{A:Consec {A:IsLoss}}"));
Max consec. win :   <% $maxgaincons %>  Max consec. loss :   <% $maxlosscons %>
%
% my $gsum = sprintf ("%10.2f", $proc->calc("{A:Sum {A:Gain}}"));
% my $lsum = sprintf ("%10.2f", $proc->calc("{A:Sum {A:Losses}}"));
% my $avggain = sprintf("%7.2f",100*$proc->calc("{A:AvgGain}") );
% my $avgloss = sprintf("%7.2f",100*$proc->calc("{A:AvgLoss}") );
% my $avgperf = sprintf("%7.2f", 100*$proc->calc("{A:AvgPerformance}") );
Average gain :   <% $avggain %>%  Average loss :    <% sprintf("%7.2f", $avgloss) %>%  Avg. perf  : <% $avgperf %>%
%
% my $biggain = sprintf("%7.2f",100*$proc->calc("{A:Max {A:NetGainPercent}}") );
% my $bigloss = sprintf("%7.2f",100*$proc->calc("{A:Min {A:NetGainPercent}}") );
% my $pf = sprintf ("%7.2f", $proc->calc("{A:ProfitFactor}"));
% my $r4 = sprintf ("%6.2f", 100*$proc->calc("{A:R4}"));
% my $rrr = sprintf ("%9.6f", $proc->calc("{A:RiskReturn}"));
Biggest gain :   <% $biggain %>%  Biggest loss :    <% $bigloss %>%  Profit fac :  <% $pf %>
Sum of gains : <% $gsum %>  Sum of losses : <% $lsum %>  Risk of ruin :<% $r4 %>%
Risk-Return :   <% $rrr %>

% ### Theoretical analysis (10keuros, full portfolio reinvested)
% #Analysis of the portfolio (1990-11-26 / 2003-11-06) :
% #-----------------------------------------------------
% #Performance : 196.9% (  8.7%)	  Buy & Hold : 158.7% (  7.6%) () => by year
% #MaxDrawDown :       29.6%  B&H MaxDrawDown :    72.7%
% #Best performance : 207.3%  Worst performance :  -7.1%
% #Net gain :       19694.62  Gross gain :      20578.77
% #
% #Trades statistics :
% #Number of gains :      22  Number of losses :      34  Win. ratio :   39.3%
% #Max consec. win :       3  Max consec. loss :       5
% #Average gain :     12.24%  Average loss :      -4.18%  Avg. perf  :   1.96%
% #Biggest gain :     60.20%  Biggest loss :     -11.53%  Profit fac :    2.93
% #Sum of gains :   43370.15  Sum of losses :  -23675.54  Risk of ruin : 20.3%


% #<% $proc->calc("{A:AvgCosts}") %>