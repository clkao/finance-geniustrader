package GT::Indicators::CNDL;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES @DEFAULT_ARGS);

use GT::Indicators;
use GT::Indicators::BOL;
use GT::Prices;

@ISA = qw(GT::Indicators);
@NAMES = ("CNDL[#*]");
@DEFAULT_ARGS = (55, 0.5, "{I:Prices OPEN}", "{I:Prices HIGH}",
		 "{I:Prices LOW}", "{I:Prices CLOSE}");

=pod

=head1 GT::Indicators::CNDL

=head2 Overview

The CandelCode (CNDL) indicator is based on the article "Coding Candelsticks" published in Technical Analysis of Stocks and Commodities (November 1999) by Viktor Likhovidov.

=head2 Calculation

=head2 Parameters

Two parameters are used to initialize the Bollinger Bands necessary to calculate all required thresholds; the standard deviation number is set to 0.5 with a period of 55.

=head2 Examples

GT::Indicators::CNDL->new()
GT::Indicators::CNDL->new([55, 0.5])

=head2 Appendix

If you need to find quickly the candel code of a specific pattern, here is a conversion table :
/GT/Docs/CandelsticksCodes

=head2 Links

http://www.traders.com/Documentation/FEEDbk_docs/Archive/012000/TradersTips/TradersTips.html

=cut


sub initialize {
    my $self = shift;
    
    # Initialize Body Thresholds

    my $evalbody = "{I:Generic:Eval abs(" . 
	$self->{'args'}->get_arg_names(3) . " - " .
	$self->{'args'}->get_arg_names(6) . ")}";
    
    $self->{'body_thresholds'} =
	GT::Indicators::BOL->new([$self->{'args'}->get_arg_names(1),
				  $self->{'args'}->get_arg_names(2),
				  $evalbody
				  ]);
    
    # Initialize Upper Shadow Thresholds

    my $evalupper = "{I:Generic:Eval " .
	$self->{'args'}->get_arg_names(6) . " >= " .
	$self->{'args'}->get_arg_names(3) . " ? " .
	$self->{'args'}->get_arg_names(4) . " - " .
	$self->{'args'}->get_arg_names(6) . " : " .
	$self->{'args'}->get_arg_names(4) . " - " .
	$self->{'args'}->get_arg_names(3) . "}";

    $self->{'upper_shadow_thresholds'} =
	GT::Indicators::BOL->new([$self->{'args'}->get_arg_names(1),
				  $self->{'args'}->get_arg_names(2),
				  $evalupper
				  ]);
	
    # Initialize Lower Shadow Thresholds

    my $evallower = "{I:Generic:Eval " .
	$self->{'args'}->get_arg_names(6) . " >= " .
	$self->{'args'}->get_arg_names(3) . " ? " .
	$self->{'args'}->get_arg_names(3) . " - " .
	$self->{'args'}->get_arg_names(5) . " : " .
	$self->{'args'}->get_arg_names(6) . " - " .
	$self->{'args'}->get_arg_names(5) . "}";

    $self->{'lower_shadow_thresholds'} =
	GT::Indicators::BOL->new([$self->{'args'}->get_arg_names(1),
				  $self->{'args'}->get_arg_names(2),
				  $evallower
				  ]);
}

sub calculate {
    my ($self, $calc, $i) = @_;
    my $indic = $calc->indicators;
    my $period = $self->{'args'}->get_arg_values($calc, $i, 1);
    my $cndl_name = $self->get_name(0);
    my $cndl_code = 0;
    my $body_color = 0;
    
    return if (! defined($period));

    $self->remove_volatile_dependencies();
    $self->add_volatile_indicator_dependency($self->{'body_thresholds'}, $period);
    $self->add_volatile_indicator_dependency($self->{'upper_shadow_thresholds'}, $period);
    $self->add_volatile_indicator_dependency($self->{'lower_shadow_thresholds'}, $period);

    return if ($indic->is_available($cndl_name, $i));
    return if (! $self->check_dependencies($calc, $i));

    # Calculate the size of : Body, Lower and Upper Shadows
    my $body = abs($self->{'args'}->get_arg_values($calc, $i, 3) -
		   $self->{'args'}->get_arg_values($calc, $i, 6));

    my $upper_shadow = ($self->{'args'}->get_arg_values($calc, $i, 6) >=
			$self->{'args'}->get_arg_values($calc, $i, 3)) ?
			($self->{'args'}->get_arg_values($calc, $i, 4) -
			 $self->{'args'}->get_arg_values($calc, $i, 6)) :
			 ($self->{'args'}->get_arg_values($calc, $i, 4) -
			  $self->{'args'}->get_arg_values($calc, $i, 3));

    my $lower_shadow = ($self->{'args'}->get_arg_values($calc, $i, 6) >=
			$self->{'args'}->get_arg_values($calc, $i, 3)) ?
			($self->{'args'}->get_arg_values($calc, $i, 3) -
			 $self->{'args'}->get_arg_values($calc, $i, 5)) :
			 ($self->{'args'}->get_arg_values($calc, $i, 6) -
			  $self->{'args'}->get_arg_values($calc, $i, 5));

    # Get all thresholds
    my $body_upper_threshold =
	$indic->get($self->{'body_thresholds'}->get_name(1), $i);
    my $body_lower_threshold =
	$indic->get($self->{'body_thresholds'}->get_name(2), $i);
    my $upper_shadow_upper_threshold =
	$indic->get($self->{'upper_shadow_thresholds'}->get_name(1), $i);
    my $upper_shadow_lower_threshold =
	$indic->get($self->{'upper_shadow_thresholds'}->get_name(2), $i);
    my $lower_shadow_upper_threshold =
	$indic->get($self->{'lower_shadow_thresholds'}->get_name(1), $i);
    my $lower_shadow_lower_threshold =
	$indic->get($self->{'lower_shadow_thresholds'}->get_name(2), $i);

    # Determine the candelstick code with a sequence of seven binary digits

    # Step 1 : Candelstick Color
    # The first binary digit represents the color of the candelstick : one (1) for a white one, and zero (0) for a black one.
    # A Doji candelstick - which as zero body size - is white if its upper shadow is longer than its lower shadow.
    if ((($self->{'args'}->get_arg_values($calc, $i, 6) -
	  $self->{'args'}->get_arg_values($calc, $i, 3)) > 0 ) 
	or 
	(($body eq 0) and ($upper_shadow > $lower_shadow)))
    {
	$body_color = 1;
	$cndl_code += (2 ** 6);
    }

    # Step 2 : Candelstick Body
    # The second position, composed of two binary digits, denotes body size, depending on the first digit, or color, of the body.
    
    # Candelsticks	    White   Black
    # No body size (doji)   00	    11
    # Small body	    01	    10
    # Middle body	    10	    01
    # Large body	    11	    00
    
    if ((($body eq 0) and ($upper_shadow <= $lower_shadow)) 
	or 
	(($body_color eq 1) and ($body >= $body_upper_threshold)))
    {
	$cndl_code += (2 ** 5 + 2 ** 4);
    }
    if ((($body_color eq 0) and ($body_lower_threshold <= $body) and 
	 ($body < $body_upper_threshold)) 
	or 
	(($body_color eq 1 ) and ($body < $body_lower_threshold) and
	 ($body > 0)))
    {
	$cndl_code += (2 ** 4);
    }
    if ((($body_color eq 0) and ($body < $body_lower_threshold) and
	 ($body > 0)) 
	or 
	(($body_color eq 1) and ($body_lower_threshold <= $body) and 
	 ($body < $body_upper_threshold)))
    {
	$cndl_code += (2 ** 5);
    }
    
    # Step 3 : Candelstick Shadows
    # The fird and the fourth positions (each consisting of two binay digits) code the sizes of upper and lower shadows, repecitvely :
    #
    # Shadows	Upper   Lower
    # None	00	11
    # Small	01	10
    # Middle	10	01
    # Large	11	00

    if (($upper_shadow < $upper_shadow_lower_threshold) and
        ($upper_shadow > 0)) {
	$cndl_code += (2 ** 2);
    }
    if (($upper_shadow_lower_threshold <= $upper_shadow) and
	($upper_shadow < $upper_shadow_upper_threshold)) {
	$cndl_code += (2 ** 3);
    }
    if ($upper_shadow >= $upper_shadow_upper_threshold) {
	$cndl_code += (2 ** 3 + 2 ** 2);
    }
    if (($lower_shadow < $lower_shadow_lower_threshold) and
	($lower_shadow > 0)) {
	$cndl_code += (2 ** 1);
    }
    if (($lower_shadow_lower_threshold <= $lower_shadow) and
	($lower_shadow < $lower_shadow_upper_threshold)) {
	$cndl_code += (2 ** 0);
    }
    if ($lower_shadow eq 0) {
	$cndl_code += (2 ** 1 + 2 ** 0);
    }
    
    # Return the results
    $indic->set($cndl_name, $i, $cndl_code);
}

1;
