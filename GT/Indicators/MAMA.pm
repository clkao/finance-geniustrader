package GT::Indicators::MAMA;

# Copyright 2008 Karsten Wippler
# Based on and for GeniusTrader (C) 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# $Id: MAMA.pm,v 1.3 2008/03/14 17:11:16 ras Exp ras $

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::SMA;

@ISA = qw(GT::Indicators);
@NAMES = ("MAMA[#*]","FAMA[#*]","PERIOD[#*]","ALPHA[#*]");
@DEFAULT_ARGS = (0.5,0.05,"{I:MEAN}");

=head1 NAME

GT::Indicators::MAMA - Mesa Adaptive Moving Average

=head1 DESCRIPTION

please see Ehlers work

=head2 Parameters

=over

=item Period (default 20)

=back

=head2 Creation

 GT::Indicators::MAMA->new()

=cut
sub initialize {
    my ($self) = @_;
    for (my $i=1;$i<=2;$i++) {
      die "Argument $i must be a constant value.\n" unless $self->{'args'}->is_constant($i);
    }
    $self->{'sma'} = GT::Indicators::SMA->new([9,$self->{'args'}->get_arg_names(3)]);
    $self->add_indicator_dependency($self->{'sma'}, 29);
    $self->add_arg_dependency(3, 20);
}

sub calculate_interval {
	my ($self, $calc, $first, $last) = @_;
	my $indic = $calc->indicators;
	my $mama_name = $self->get_name(0);
	my $fama_name = $self->get_name(1);
	my $period_name = $self->get_name(2);
	my $alpha_name = $self->get_name(3);
	my $alpha = 0.5;
	my @smooth=(0,0,0,0,0,0,0);
	my @detrend=(0,0,0,0,0,0,0);
	my @var_Q1=(0,0,0,0,0,0,0);
	my @var_I1=(0,0,0,0,0,0,0);
	my $var_JI;
	my $var_JQ;
	my @var_I2=(0,0);
	my @var_Q2=(0,0);
	my @var_RE=(0,0);
	my @var_IM=(0,0);
	my $new;
	my @temp_period=(0,0);
	my $pi=3.141592653589793;
	my @phase=(0,0);
	my $delta_phase;

	return if ($indic->is_available_interval($mama_name, $first, $last));
	# Don't need to calculate all SMA values, just the first data point.
        while (! $self->check_dependencies_interval($calc, $first, $last)) {
            return if $first == $last;
            $first++;
        }
	$indic->set($mama_name, $first-18, $indic->get($self->{'sma'}->get_name, $first-18));
	$indic->set($fama_name, $first-18, $indic->get($self->{'sma'}->get_name, $first-18));

	for (my $i=$first-17;$i<=$last;$i++) {
		$new=(4*$self->{'args'}->get_arg_values($calc, $i, 3)+
		      3*$self->{'args'}->get_arg_values($calc, $i-1, 3)+
		      2*$self->{'args'}->get_arg_values($calc, $i-2, 3)+
		      1*$self->{'args'}->get_arg_values($calc, $i-3, 3))/10;
	        unshift(@smooth, $new); pop @smooth;
		$new=hilbert((@smooth,$temp_period[1]));
	        unshift(@detrend, $new); pop @detrend;
		$new=hilbert((@detrend,$temp_period[1]));
	        unshift(@var_Q1, $new); pop @var_Q1;
		$new=$detrend[3];unshift(@var_I1, $new); pop @var_I1;
		$var_JI=hilbert((@var_I1,$temp_period[1]));
		$var_JQ=hilbert((@var_Q1,$temp_period[1]));
		$new=$var_I1[0]-$var_JQ;
	        unshift(@var_I2, $new); pop @var_I2;
		$var_I2[0]=0.2*$var_I2[0]+0.8*$var_I2[1];
		$new=$var_Q1[0]+$var_JI;
	        unshift(@var_Q2, $new); pop @var_Q2;
		$var_Q2[0]=0.2*$var_Q2[0]+0.8*$var_Q2[1];
		$new=$var_I2[0]*$var_I2[1]+$var_Q2[0]*$var_Q2[1];
	        unshift(@var_RE, $new); pop @var_RE;
		$var_RE[0]=0.2*$var_RE[0]+0.8*$var_RE[1];
		$new=$var_I2[0]*$var_Q2[1]-$var_Q2[0]*$var_I2[1];
	        unshift(@var_IM, $new); pop @var_IM;
		$var_IM[0]=0.2*$var_IM[0]+0.8*$var_IM[1];
		if ($var_RE[0] != 0 && $var_IM[0] != 0){
		$new=atan2($var_IM[0],$var_RE[0]);
		$new=$new*180/$pi;
		$new=360/$new;
		}
	        unshift(@temp_period, $new); pop @temp_period;
		if ($temp_period[0]>1.5*$temp_period[1]){$temp_period[0]=1.5*$temp_period[1];}
		if ($temp_period[0]<0.67*$temp_period[1]){$temp_period[0]=0.67*$temp_period[1];}
		if ($temp_period[0]<6){$temp_period[0]=6;}
		if ($temp_period[0]>50){$temp_period[0]=50;}
		$temp_period[0]=0.2*$temp_period[0]+0.8*$temp_period[1];
		$indic->set($period_name, $i, $temp_period[0]);
		if($var_I1[0] !=0){
			$new=atan2($var_Q1[0],$var_I1[0]);
			$new=$new*180/$pi;
		} else {
		$new=0;
		}
	        unshift(@phase, $new); pop @phase;
		$delta_phase=$phase[1]-$phase[0];
		if($delta_phase<1){$delta_phase=1;}
		$alpha=$self->{'args'}->get_arg_values($calc, $i, 1)/$delta_phase;
		if($alpha<$self->{'args'}->get_arg_values($calc, $i, 2)){$alpha=$self->{'args'}->get_arg_values($calc, $i, 2);}
		$indic->set($alpha_name, $i, $alpha);
		my $oldmama = $indic->get($mama_name, $i - 1);
		my $oldfama = $indic->get($fama_name, $i - 1);
		my $mama = $alpha * ($self->{'args'}->get_arg_values($calc, $i, 3) - $oldmama) + $oldmama;
		my $fama = 0.5*$alpha * ($mama - $oldfama) + $oldfama;
		$indic->set($mama_name, $i, $mama);
		$indic->set($fama_name, $i, $fama);
	}

}

sub hilbert {
	my (@data) =@_;
	my ($return_value);
	my ($const_a) = 0.0962;
	my ($const_b) = 0.5769;
	my ($div) = 0.075*$data[7]+0.54;
	$return_value=($const_a*$data[0]+$const_b*$data[2]-$const_b*$data[4]-$const_a*$data[6])*$div;
	return $return_value;
}

1;
