package GT::Analyzers::Process;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

use GT::ArgsTree;
use GT::Prices;
use GT::Calculator;
use GT::Conf;
use GT::Eval;
use GT::BackTest::Spool;
use GT::BackTest;
use GT::Portfolio;
use GT::PortfolioManager;
use GT::DateTime;
use GT::Tools qw(:conf);
use GT::Analyzers::Report;

use Compress::Zlib ;
use Data::Dumper;
use IO::Handle;

use GT::Brokers::InteractiveBrokers;
use GT::Brokers::NoCosts;

# Uncomment this to use PGPLOT instead of R:
# use PGPLOT;
# use Chart::Math::Axis;

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw($term);
our $term;
our $myself;

=head1 NAME

  GT::Analyzers::Process

=head1 DESCRIPTION

This module offes all those functions that are needed by the analyzers
shell to interactively analyze and test portfolios.

=head2 FUNCTIONS

=over

=item C<< GT::Analyzers::Process->new() >>

=cut

############################################################
sub new { # Generate a new Object
############################################################
  my $type = shift;
  my $args = \@_;
  my $class = ref($type) || $type;
  my $self = {};
  bless $self, $class;

  $self->{'db'} = create_standard_object("DB::" . GT::Conf::get("DB::module"));

  $self->{'VERSION'} = "0.5";
  %{$self->{'config'}} = ( 'code' => '',
			   'first' => 'auto',
			   'timeframe' => 'day',
			   'expert' => '1',
			   'last' => 'auto',
			   'full' => 0,
			   'broker' => GT::Conf::get("Brokers::module"),
			   'system' => "Systems::Generic {S:Generic:CrossOverUp {I:SMA 20} {I:SMA 60}} " . 
			               "{S:Generic:CrossOverDown {I:SMA 20} {I:SMA 60}}",
			   'cs' => "OppositeSignal",
			   'tf' => "OneTrade",
			   'mm' => [ 'Basic' ]
			 );
  $self->set_code( $self->{'config'}{'code'} ) if (defined($term));

  %{$self->{'CMDS'}} = map { $_ => \&$_ } 
    qw(bye set load save calc calc_array licence license help p info btest report list source);

  if ( defined($term) && -r ".AnaShHistory" ) {
    open IN, ".AnaShHistory";
    while (<IN>) {
      chomp;
      $term->addhistory( $_ );
    }
    close IN;
  }

#  In a later version the hole workspace should be restored:
#  This code is not working due to the code references...
#
#  if ( -r ".AnaShData" ) {
#    my $gz = gzopen(".AnaShData", "rb");
#    my $text = "";
#    while ($gz->gzreadline($_) > 0) {
#      $text .= $_;
#    }
#    my $VAR1;
#    eval $text;
#    if (! $@) {
#      map { $self->{$_} => $VAR1->{$_} } 
#	qw(calc q first config pf );
#   }
#  }

  $myself = $self if ( $self->{'config'}{'expert'} == 1);

  return $self;
}


=item C<< GT::Analyzers::Process->parse( $cmd ) >>

This function parses the command $cmd. If the shell is set in expert
mod it tries first to map $cmd to an internat command and otherwise
evaluates it using eval.

=cut

############################################################
sub parse {
############################################################
  no strict "vars";
  my $self = shift;
  my $cmd = shift;
  $cmd =~ s/^\s*//;
  $cmd =~ s/\s*$//;
  return if ($cmd =~ /^\s*$/);
  return if ($cmd =~ /^#/);
  my ($func, $params) = split ' ', $cmd, 2;
	
  my $erg = "";
  if ( defined( $self->{'CMDS'}{$func} ) ) {
    my @param = split /\s+/, $params;
    $erg = $self->{'CMDS'}{$func}->($self, @param);
  } else {
    if ( $self->{'config'}{'expert'} == 1 ) {
      eval ( $func . " " . $params );
      print "Error:  $@\n" if ($@);

    } else {
      print "Command not found: '$func' ($params) \n";
    }
  }

  return $erg;
}

=item C<< GT::Analyzers::Process->bye() >>

Exits the program after asking if the history should be stored.

=cut

############################################################
sub bye {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
  print "Exiting Olf's Analyzer...\n";
  if ( defined( $term ) ) {
    my $leave = 0;
    while ($leave != 1) {
      print "Save settings? [Y/n]: ";
      my $answer = <>;
      chomp( $answer );
      if ( lc($answer) eq "y" || lc($answer) eq "" ) {
	open OUT, ">.AnaShHistory";
	my @history = $term->GetHistory();
	@history = splice @history, ($#history-100), 100 if ($#history > 100);
	print OUT join("\n", @history ) . "\n";
	close OUT;

#       Later some code like this one should store the hole workspace:
#
#	open OUT, ">.AnaShData";
#	my $buffer =  Compress::Zlib::memGzip( Dumper( $self ) );
#	print OUT $buffer;
#	close OUT;

	$leave = 1;
      } elsif ( lc($answer) eq "n" ) {
	$leave = 1;
      } else {
	print "Please answer yes or no!\n";
      }
    }
  }
  $self->disconnect();
  exit;
}

=item C<< GT::Analyzers::Process->set( [ $key ] ) >>

Set a configuration-parameter. If key is not given, the list of
parameters is given. The variable key consits of the real key and the
value separated by a space. If you want to set an array, you can
either use key[x] to teh xth element or +key to add the value to the
array.

=cut

############################################################
sub set {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }

  my $nb;
  my $skey = shift;
  my $val = join(" ", @_);
  if ($skey =~ /(\w+)\[(\d+)\]/) {
    $skey = $1;
    $nb = $2;
  }

  if ( !defined($skey) ) {
    print "Settings:\n";
    foreach my $key ( keys %{$self->{'config'}} ) {
      if ( ref($self->{'config'}{$key}) =~ /ARRAY/ ) {
	for my $i (0..$#{$self->{'config'}{$key}} ) {
	  print "  $key " . "[" . $i . "] => " . $self->{'config'}{$key}->[$i] . "\n";
	}
      } else {
	print "  $key => " . $self->{'config'}{$key} . "\n";
      }
    }
  } else {
      # Add value
    if ( $skey =~ /^\+(.*)/ ) {
      $skey = $1;
      if ( ref($self->{'config'}{$skey}) =~ /ARRAY/ ) {
	push @{$self->{'config'}{$skey}}, $val;
      } else {
	if ( defined($self->{'config'}{$skey}) &&
	     $self->{'config'}{$skey} ne "" ) {
	  my $erg = $self->{'config'}{$skey};
	  undef( $self->{'config'}{$skey} );
	  push @{$self->{'config'}{$skey}}, $erg;
	}
	push  @{$self->{'config'}{$skey}}, $val;
      }
    } else {
      if ( defined($nb) ) {
	if ($val =~ /^\s*$/ ) {
	  splice @{$self->{'config'}{$skey}}, $nb, 1;
	} else {
	  $self->{'config'}{$skey}->[$nb] = $val;
	}
      } else {
	$self->{'config'}{lc($skey)} = $val;
	undef ($self->{'config'}{lc($skey)}) if ( $val eq "" );
	if ( lc($skey) eq "code" ) {
	  unless ( defined( $self->{'config'}{'noloadcode'} ) &&
		   $self->{'config'}{'noloadcode'} == 1 ) {
	    $self->set_code( $val, 1 );
	  }
	}
	$myself = $self if (lc($skey) eq "expert" && !defined($myself) && $val == 1 );
      }
    }
  }
  return "";
}

=item C<< GT::Analyzers::Process->set_code( $code ) >>

Set the code and do the necessary initialization-stuff.

=cut

############################################################
sub set_code {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
  my $param = shift;
  my $chngtime = shift;
  $chngtime = 0 if (!defined($chngtime));

  $self->{'config'}{'code'} = $param;
  $self->{'q'} = $self->{'db'}->get_prices($self->{'config'}{'code'});
  $self->{'calc'} = GT::Calculator->new( $self->{'q'} );
  $self->{'calc'}->set_code($self->{'config'}{'code'});

  if ($self->{'config'}{'timeframe'} ne "day") {
    if (! $self->{'calc'}->set_current_timeframe( 
            GT::DateTime::name_to_timeframe($self->{'config'}{'timeframe'})) ) {
      warn "Can't create « ".$self->{'config'}{'timeframe'}." » timeframe ...\n";
    }
  }

  $self->{'c'} = $self->{'calc'}->prices->count;

  return if ($chngtime == 0);

  $self->{'last'} = $self->{'c'} - 1;
  $self->{'first'} = $self->{'c'} - 2 * GT::DateTime::timeframe_ratio($YEAR, 
								      $self->{'calc'}->current_timeframe);

  $self->{'first'} = 0 if ($self->{'config'}{'full'});
  $self->{'first'} = 0 if ($self->{'first'} < 0);

  if ( $self->{'config'}{'first'} ne "auto" ) {
    my $date = $self->{'calc'}->prices->find_nearest_following_date( $self->{'config'}{'first'} );
    $self->{'first'} = $self->{'calc'}->prices->date($date);
  } elsif ( $self->{'config'}{'first'} =~ /^\d+$/ ) {
    $self->{'first'} = $self->{'config'}{'first'};
    $self->{'first'} = 0 if ($self->{'first'} < 0);
    $self->{'first'} = $self->{'c'} - 1 if ($self->{'first'} >= $self->{'c'});
  }

  if ( $self->{'config'}{'last'} ne "auto" ) {
    my $date = $self->{'calc'}->prices->find_nearest_preceding_date($self->{'config'}{'last'});
    $self->{'last'} = $self->{'calc'}->prices->date($date);
  } elsif ( $self->{'config'}{'last'} =~ /^\d+$/ ) {
    $self->{'last'} = $self->{'config'}{'last'};
    $self->{'last'} = 0 if ($self->{'last'} < 0);
    $self->{'last'} = $self->{'c'} - 1 if ($self->{'last'} >= $self->{'c'});
  }

  $self->{'calc'}->{'first'} = $self->{'first'};
  $self->{'calc'}->{'last'} = $self->{'last'};
}

=item C<< GT::Analyzers::Process->load( $sys, $dir, $code ) >>

Loads $sys from $dir and $code (optional).

=cut

############################################################
sub load {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }

  my ($sys, $dir, $code) = @_;
  if ( defined($code) ) {
    $self->set_code ( $code );
  } else {
    $self->set_code( $self->{'config'}{'code'} );
  }

  # Load a single portfolio
  if ( -e $sys ) {#=~ /^\./ || $sys =~ /^\// ) {
    $self->{'pf'} = GT::Portfolio->create_from_file($sys);
    my $name = GT::Conf::get("Brokers::module");
    $self->{'pf'}->{'broker'} = create_standard_object(split (/\s+/, "Brokers::$name"));
    $self->{'calc'}->{'pf'} = $self->{'pf'};

     my @dates = sort {$a cmp $b} keys %{$self->{'pf'}->{'evaluation_history'}};
     @dates = grep { ref($_) !~ /ARRAY/ } @dates;
     my $dat = $self->{'calc'}->prices->find_nearest_date( $dates[0] );
     $self->{'first'} = $self->{'calc'}->prices->date($dat);
     $dat = $self->{'calc'}->prices->find_nearest_date( $dates[$#dates] );
     $self->{'last'} = $self->{'calc'}->prices->date($dat);

    return;
  }

  # Load a portfolio from a backtest-dir
  my $directory;
  if (defined($dir) && $dir) {
    $directory = $dir;
  } elsif (GT::Conf::get("BackTest::Directory")) {
    $directory = GT::Conf::get("BackTest::Directory");
  }

  if (! (defined($directory) && $sys)) {
    die "Bad syntax for BackTestPortfolio(sysname, directory) !\n";
  }
	
  my $spool = GT::BackTest::Spool->new($directory);

  my $index = $spool->{'index'};
  $self->{'pf'}->{'name'} = $sys;
  foreach my $a ( keys %{$index->{'alias'}} ) {
    $self->{'pf'}->{'name'} = $index->{'alias'}{$a} if ($a eq $sys);
  }
  $self->{'pf'} = $spool->get_portfolio($self->{'pf'}->{'name'},
					$self->{'config'}{'code'});
  $self->{'pf'}->{'name'} = $sys if ( $self->{'pfname'} eq "" );

  foreach my $a ( keys %{$index->{'alias'}} ) {
    $self->{'pf'}->{'name'} = $a if ($index->{'alias'}{$a} eq $sys);
  }

  my $name = $self->{'pf'}->{'broker'}->{'names'}[0];
  $name =~ s/[\[\],]/ /g;
  $name = GT::Conf::get("Brokers::module") if ($name =~ /^\s*$/);
  $self->{'pf'}->{'broker'} = create_standard_object(split (/\s+/, "Brokers::$name"));

  $self->{'calc'}->{'pf'} = $self->{'pf'};

  my @dates = sort {$a cmp $b} keys %{$self->{'pf'}->{'evaluation_history'}};
  @dates = grep { ref($_) !~ /ARRAY/ } @dates;
  my $dat = $self->{'calc'}->prices->find_nearest_date( $dates[0] );
  $self->{'first'} = $self->{'calc'}->prices->date($dat);
  $dat = $self->{'calc'}->prices->find_nearest_date( $dates[$#dates] );
  $self->{'last'} = $self->{'calc'}->prices->date($dat);

  my $stats = $spool->get_stats($sys, $self->{'config'}{'code'});
  $self->{'analysis'}->{'portfolio'} = $self->{'pf'};
  $self->{'analysis'}->{'real'}{'std_performance'} = $stats->[0];
  $self->{'analysis'}->{'real'}{'performance'} = $stats->[1];
  $self->{'analysis'}->{'real'}{'max_draw_down'} = $stats->[2];
  $self->{'analysis'}->{'real'}{'std_buyandhold'} = $stats->[3];
  $self->{'analysis'}->{'real'}{'buyandhold'} = $stats->[4];

  $self->{'calc'}->{'first'} = $self->{'first'};
  $self->{'calc'}->{'last'} = $self->{'last'};

  return "" unless(defined($term));
  return "Loaded Portfolio $sys...\n";
}

=item C<< GT::Analyzers::Process->save( $sys, $dir ) >>

Saves the portfolio with name $sys to directory $dir.

=cut

############################################################
sub save {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
#  my $self = shift;
  my ($alias, $dir) = @_;
  $dir = "./" if ( !defined($dir) );
  delete( $self->{'analysis'}->{'portfolio'}->{objects} )
    if defined( $self->{'analysis'}->{'portfolio'}->{objects} );

  my $bkt_spool = GT::BackTest::Spool->new($dir);
  my $stats = [ $self->{'analysis'}->{'real'}{'std_performance'},
		$self->{'analysis'}->{'real'}{'performance'},
		$self->{'analysis'}->{'real'}{'max_draw_down'},
		$self->{'analysis'}->{'real'}{'std_buyandhold'},
		$self->{'analysis'}->{'real'}{'buyandhold'}
	      ];

  $alias = $self->{'config'}{'alias'} if ( !defined($alias) );
  $alias = $self->{'sys_manager'}->alias_name if ( !defined($alias) );
  my $name = $alias;

  $name = $self->{'pf'}->{'name'} if ( defined($self->{'pf'}->{'name'}) && 
				       $self->{'pf'}->{'name'} ne "" );
  $name = $self->{'sys_manager'}->{'name'} if (defined($self->{'sys_manager'}) && 
					       $self->{'sys_manager'}->{'name'} ne "");

  $bkt_spool->add_alias_name($name, $alias); #self->{'sys_manager'}->get_name(), $alias);
  $bkt_spool->add_results($name, $self->{'config'}{'code'}, $stats,
			  $self->{'analysis'}->{'portfolio'}, $self->{'config'}{'code'} );
  $bkt_spool->sync();

  return "" unless(defined($term));
  return "Saved $alias in $dir...\n";
}

=item C<< GT::Analyzers::Process->list( $dir ) >>

Lists the systems in directory $dir.

=cut

############################################################
sub list {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
  my $dir = shift;
  my $bkt_spool = GT::BackTest::Spool->new($dir);
  my $list = $bkt_spool->list_available_data();
  if ( wantarray() ) {
    return %{$list};
  } else {
    my $erg = "";
    foreach my $key ( %{$list} ) {
      next if ( ref($key) =~ /ARRAY/ );
      $erg .= " ==> " .  $key . "\n";
      if ( $bkt_spool->get_alias_name( $key ) ) {
	$erg .= "     Alias: " . $bkt_spool->get_alias_name( $key ) . "\n";
      }
      foreach my $code ( @{$list->{$key}} ) {
	$erg .= " " x 5 . " --> " . $code . "\n";
      }
    }
    return $erg;
  }
}

=item C<< GT::Analyzers::Process->btest() >>

start the backtest.

=cut

############################################################
sub btest {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
  # If prepare is set, only prepare Backtest - don't test!
  my $prepare = shift;
  $prepare = 0 if (!defined($prepare));

  my $start = time();

  $self->{'pf_manager'} = GT::PortfolioManager->new;
  $self->{'sys_manager'} = GT::SystemManager->new;

  # Clear calc-object
  $self->set_code( $self->{'config'}{'code'}, 1 ); #{'calc'} = GT::Calculator->new( $self->{'q'} );

  # Set up the System or alias
  if ( defined($self->{'config'}{'system'}) && $self->{'config'}{'system'} ne "" ) {
    $self->{'sys_manager'}->set_system( create_standard_object( split (/\s+/, $self->{'config'}{'system'})) );
  } elsif ( defined($self->{'config'}{'alias'}) && $self->{'config'}{'alias'} ne "" ) {
    my $alias = $self->{'config'}{'alias'};
    my $sysname = resolve_alias($alias);
    if (defined($sysname) && $sysname) {
      $self->{'sys_manager'}->setup_from_name($sysname);
      $self->{'pf_manager'}->setup_from_name($sysname);
    } else {
      return "ERROR: Could not resolve alias.\n";
    }
  } else {
    return "ERROR: No alias or system given!\n";
  }

  # Add Money Management
  if ( ref($self->{'config'}{'mm'}) =~ /ARRAY/ ) {
    foreach my $mm ( @{$self->{'config'}{'mm'}} ) {
      $self->{'pf_manager'}->add_money_management_rule( create_standard_object(split (/\s+/, "MoneyManagement::$mm")));
    }
  } else {
    $self->{'pf_manager'}->add_money_management_rule( create_standard_object(split (/\s+/, "MoneyManagement::" . $self->{'config'}{'mm'})));
  }
  $self->{'pf_manager'}->default_money_management_rule( create_standard_object("MoneyManagement::Basic") );
  $self->{'pf_manager'}->finalize;

  # Add Order-Factories
  if ( defined($self->{'config'}{'of'}) && $self->{'config'}{'of'} ne "" ) {
    $self->{'sys_manager'}->set_order_factory( create_standard_object(split (/\s+/, "OrderFactory::" . $self->{'config'}{'of'})));
  }

  # Add Tradefilters
  if ( ref($self->{'config'}{'tf'}) =~ /ARRAY/ ) {
    foreach my $tf ( @{$self->{'config'}{'tf'}} ) {
      $self->{'sys_manager'}->add_trade_filter( create_standard_object(split (/\s+/, "TradeFilters::$tf")));
    }
  } elsif ( defined($self->{'config'}{'tf'}) && $self->{'config'}{'tf'} ne "" ) {
      $self->{'sys_manager'}->add_trade_filter( create_standard_object(split (/\s+/, "TradeFilters::" . $self->{'config'}{'tf'})));
  }

  # Add Closingstrategies
  if ( ref($self->{'config'}{'cs'}) =~ /ARRAY/ ) {
    foreach my $cs ( @{$self->{'config'}{'cs'}} ) {
      $self->{'sys_manager'}->add_position_manager( create_standard_object(split (/\s+/, "CloseStrategy::$cs")));
    }
  } else {
    $self->{'sys_manager'}->add_position_manager( create_standard_object(split (/\s+/, "CloseStrategy::" . $self->{'config'}{'cs'})));
  }

  $self->{'sys_manager'}->finalize;

  $self->{'analysis'} = backtest_single($self->{'pf_manager'}, 
					$self->{'sys_manager'},
					$self->{'config'}{'broker'},
					$self->{'calc'},
					$self->{'first'},
					$self->{'last'}) unless ($prepare == 1);

  $self->{'pf'} = $self->{'analysis'}->{'portfolio'};
  $self->{'calc'}->{'pf'} = $self->{'pf'};

  $self->{'pf'}->{'name'} = $self->{'sys_manager'}->get_name();

  return "" unless (defined($term));
  return "Tested ... ok in " . (time()-$start) . " seconds\n";
}


=item C<< GT::Analyzers::Process->calc($args) >>

Calculates the expression given as argument(s).

=cut

############################################################
sub calc {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
  my $args = GT::ArgsTree->new( @_ );

  my $nb = $args->get_nb_args();
  my $expr = "";
  for (my $n = 1; $n <= $nb; $n++) {
    if ($args->is_constant($n)) {
      $expr .= " " . $args->get_arg_constant($n);
    } else {
      my $ob = $args->get_arg_object($n);

      $ob->calculate($self->{'calc'}, $self->{'last'})
	if ( $ob->isa("GT::Indicators") );

      my $val = $args->get_arg_values($self->{'calc'}, $self->{'last'}, $n);
      return if (! defined($val));
      $expr .= " $val";
    }
  }
  my $res = undef;
  eval "\$res = $expr";
  if ($@) {
    warn "$@ : $expr";
    return;
  }

  return $res unless (defined($term));
  return $res . "\n";
}

=item C<< GT::Analyzers::Process->calc_array($arg1, $arg2, ...) >>

Calculates each array and prints out/returns a list.

The arry should have the same length.

=cut

############################################################
sub calc_array {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
#  my $self = shift;
  my $param = join(" ", @_ );

  my $args = GT::ArgsTree->new( $param );
  my $nb = $args->get_nb_args();
  my $expr = "";
  my $val;
  if ( $nb == 1 ) {
      $val = $args->get_arg_values($self->{'calc'}, $self->{'last'}, 1);
  } else {
      $val = ();
      push @{$val}, $args->get_arg_values($self->{'calc'}, $self->{'last'}, 1);
      for (my $n = 2; $n <= $nb; $n++) {
	  push @{$val}, $args->get_arg_values($self->{'calc'}, $self->{'last'}, $n);
      }
  }
  return if (! defined($val));
  if ( ref($val) =~ /ARRAY/ ) {
    if (wantarray()) {
      return @{$val};
    } else {
      my $erg = "";
      if ( $nb == 1 ) {
	  foreach my $i (0..$#{$val}) {
	    if (defined($term)) {
	      $erg .= "  [" . sprintf("%4d", $i) . "]   " unless (defined($self->{'config'}->{'nonb'}) &&
								  $self->{'config'}->{'nonb'} == 1);
	    } else {
	      $erg .= sprintf("%04d", $i) . "\t" unless (defined($self->{'config'}->{'nonb'}) &&
							 $self->{'config'}->{'nonb'} == 1);
	    }
	      $erg .= $val->[$i] . "\n";
	  }
      } else {
	  $erg .= "Number\t";
	  for (my $n = 1; $n <= $nb; $n++) {
	      #$erg .= $args->get_arg_names($n) . "\t";
	      $erg .= $args->get_arg_object($n)->get_name(0) . "\t";
	  }
	  $erg .= "\n";
	  foreach my $i (0..$#{$val->[0]}) {
	    if (defined($term)) {
	      $erg .= "  [" . sprintf("%4d", $i) . "]   " unless (defined($self->{'config'}->{'nonb'}) &&
								  $self->{'config'}->{'nonb'} == 1);

	    } else {
	      $erg .= sprintf("%04d", $i) . "\t" unless (defined($self->{'config'}->{'nonb'}) &&
							 $self->{'config'}->{'nonb'} == 1);
	    }

	      foreach my $j (0..$#{$val}) {
		  $erg .= $val->[$j]->[$i] . "\t";
	      }
	      $erg .= "\n";
	  }
      }
      return $erg;
    }
  }
  return $val;
}

=item C<< GT::Analyzers::Process->p($arg) >>

Prints out the string $arg and replaces the variable elements

=cut

############################################################
sub p {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
#  my $self = shift;
#  my $param = shift;
  my $args = GT::ArgsTree->new( @_ ); #split /\s+/, $param );

  my $nb = $args->get_nb_args();
  my $expr = "";
  for (my $n = 1; $n <= $nb; $n++) {
    if ($args->is_constant($n)) {
      $expr .= " " . $args->get_arg_constant($n);
    } else {
      my $val = $args->get_arg_values($self->{'calc'}, $self->{'last'}, $n);
      return if (! defined($val));
      $expr .= " $val";
    }
  }
  return $expr . "\n";
}

=item C<< GT::Analyzers::Process->help() >>

Print the help screen

=cut

############################################################
sub help {
############################################################
    return <<HELP

 Anashell support the follwing commands:
  set [name] [value]    - Without parameters: Displays settings.
                          With parameters: Set name to value.
  set +name <value>     - Adds value to the array name
  set name[3] <value>   - Sets 3rd element of name to value
                          Element is deleted if value == ''

  btest                 - Run backtest with given parameters.
  save <sys> [dir]      - Save Portfolio with alias sys to dir.
  load <sys> [dir]      - Load Portfolio for alias sys from dir.
  list <dir>            - Lists the Portfolios in directory dir.

  calc <args>           - Calculate the value of args
  calc_array <args>     - Calculate an array (or multiple arrays
                          of the same size)
  p <args>              - Print args by replacing variables

  report <file>         - Prints a report for the current
                          portfolio by using file as template.

  help                  - This help
  licence               - Show licence
  bye                   - Leave program


Only available in expert-mode (set expert 1):
  r_hist( <array-ref> ) - Displays a histogram of an array by using
                          the program R (www.r-project.org)
  r_bar( <array-ref> )  - Displays an barplot an array.
  r_corr( <ar1>,<ar2> ) - Display a correlation on array-ref ar1
                          and array-ref ar2.

HELP
}

=item C<< GT::Analyzers::Process->licence() >>

Print the licence

=cut

############################################################
sub licence {
############################################################
    license();
}

=item C<< GT::Analyzers::Process->license() >>

Prints the license

=cut

############################################################
sub license {
############################################################
    return <<GPL

 This program is free software; you can redistribute it and/or
 modify it under the terms of the GNU General Public License
 as published by the Free Software Foundation; either version 2
 of the License, or any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program; if not, write to the 

  Free Software Foundation, Inc., 59 Temple Place - Suite 330
  Boston, MA  02111-1307, USA.

 or via Internet: http://www.gnu.org/copyleft/gpl.html

GPL
}

=item C<< GT::Analyzers::Process->disconnect() >>

Disconnect from database.

=cut

############################################################
sub disconnect {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
#  my $self = shift;
  $self->{'db'}->disconnect();
}

=item C<< GT::Analyzers::Process->info() >>

Prints a small information shown at the start of anashell.

=cut

############################################################
sub info {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
#  my $self = shift;
  my $erg = "";
  $erg .= "\n  Anashell : Copyright 2004 Oliver Bossert\n";
  $erg .= "  Version: " . $self->{'VERSION'} . "\n\n";
  $erg .= "  Anashell is free software and comes with ABSOLUTE NO WARRANTY\n";
  $erg .= "  You are welcome to redistribute it under certain conditions.\n";
  $erg .= "  type licence or license for distribution details.\n\n";
  $erg .= "  Type bye to leave the program and help for help.\n\n";
  return $erg;
}

=item C<< GT::Analyzers::Process->pg_hist() >>

Uncomment this function to plot histograms with pgplot.

=cut

############################################################
sub pg_hist {
############################################################
#  my $self;
#  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
#    $self = shift;
#  } else {
#    $self = $myself;
#  }
#  my $array = shift;
#  my @sort = sort {$a <=> $b} @{$array};

#  my $Axis = Chart::Math::Axis->new();
#  $Axis->add_data( @sort );
#  my $min = $Axis->bottom;
#  my $max = $Axis->top;

#  pgbegin(0,"/xserve",1,1);
#  pgenv( $min, $max,
#	0,$#sort/2, 0, 0);
#  pglabel('X','Y','Histrogram');

#  # background
#  pgscr( 0, 1.0, 1.0, 1.0 );
#  # foreground
#  #pgscr( 1, 0.0, 0.0, 1.0 );

#  pghist($#sort, \@sort, 
#	 $min, $max, 
#	 $Axis->ticks,  1);

#  pgend;

}

=item C<< GT::Analyzers::Process->r_hist( $array ) >>

Plots a histogram using R (www.r-project.org) of the values of $array.

=cut

############################################################
sub r_hist {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
  my $array = shift;

  my $add = "main=\"Histogram\"";
  $add = $self->{'config'}{'radd'} if ($self->{'config'}{'radd'} ne "");

  my $prg = "/usr/bin/R --vanilla --no-readline -q";
  my $pid = open(RPROC, "|-");
  RPROC->autoflush();
  if ( $pid ) {
    print RPROC "png(\"/tmp/Rtmp.png\")\n";
    print RPROC "x<-scan(file=\"\")\n";
    print RPROC join("\n", @{$array}) . "\n\n";
    print RPROC "hist(c(x), " . $add . ")\n";
    close RPROC || die "Kiddie gone: $?";
  } else {
    exec $prg;
  }

  system("xv /tmp/Rtmp.png &");

# This works; but very unstable:
# use R;
# use RReferences;
# &R::initR("--silent");
# &R::library("RSPerl");
# &R::callWithNames("hist", {'', $array, 'main', 'Normals', 'xlab', ""});

# This is unstable too:
# use R::Wrapper;
# hist( { x => $array, main => 'Test Plot' } );

}

=item C<< GT::Analyzers::Process->r_bar( $array ) >>

Generates a barplot in R by using the values of $array

=cut

############################################################
sub r_bar {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
  my $array = shift;

  my $add = "main=\"Barplot\"";
  $add = $self->{'config'}{'radd'} if ($self->{'config'}{'radd'} ne "");

  my $prg = "/usr/bin/R --vanilla --no-readline -q";
  my $pid = open(RPROC, "|-");
  RPROC->autoflush();
  if ( $pid ) {
    print RPROC "png(\"/tmp/Rtmp.png\")\n";
    print RPROC "x<-scan(file=\"\")\n";
    print RPROC join("\n", @{$array}) . "\n\n";
    print RPROC "barplot(c(x), " . $add . ")\n";
    close RPROC || die "Kiddie gone: $?";
  } else {
    exec $prg;
  }

  system("xv /tmp/Rtmp.png &");
}

=item C<< GT::Analyzers::Process->r_corr( $arr1, $arr2 ) >>

Plots the correlation of $arr1 and $arr2 in R.

=cut

############################################################
sub r_corr {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
  my $arrayx = shift;
  my $arrayy = shift;

  my $add = "main=\"Correlation\"";
  $add = $self->{'config'}{'radd'} if ($self->{'config'}{'radd'} ne "");

  my $prg = "/usr/bin/R --vanilla --no-readline -q";
  my $pid = open(RPROC, "|-");
  RPROC->autoflush();
  if ( $pid ) {
    print RPROC "png(\"/tmp/Rtmp.png\")\n";
    print RPROC "x<-scan(file=\"\")\n";
    print RPROC join("\n", @{$arrayx}) . "\n\n";
    print RPROC "y<-scan(file=\"\")\n";
    print RPROC join("\n", @{$arrayy}) . "\n\n";
    print RPROC "plot(y ~ x, " . $add . ")\n";
    print RPROC "abline(lm(y ~ x), col=\"red\")\n";
    print RPROC "summary(lm(y ~ x))\n";
    close RPROC || die "Kiddie gone: $?";
  } else {
    exec $prg;
  }

  system("xv /tmp/Rtmp.png &");
}

############################################################
sub r_hist2 {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }
  my $array1 = shift;
  my $array2 = shift;

  my $add = "main=\"Histogramm-Comparison\"";
  $add = $self->{'config'}{'radd'} if ($self->{'config'}{'radd'} ne "");

  my $prg = "/usr/bin/R --vanilla --no-readline -q";
  my $pid = open(RPROC, "|-");
  RPROC->autoflush();
  if ( $pid ) {
    print RPROC "png(\"/tmp/Rtmp.png\")\n";
    print RPROC "t1<-scan(file=\"\")\n";
    print RPROC join("\n", @{$array1}) . "\n\n";
    print RPROC "t2<-scan(file=\"\")\n";
    print RPROC join("\n", @{$array2}) . "\n\n";
    print RPROC "par(mfrow=c(2,1))\n";
    print RPROC "h<-hist(t1)\n";
    print RPROC "hist(t2, breaks=h\$breaks)\n";
    close RPROC || die "Kiddie gone: $?";
  } else {
    exec $prg;
  }

  system("xv /tmp/Rtmp.png &");
}

=item C<< GT::Analyzers::Process->report( $file ) >>

Prints the report of the portfolio using $file as template.

=cut

############################################################
sub report {
############################################################
    my $self;
    if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
	$self = shift;
    } else {
	$self = $myself;
    }
    my $filename = shift;

    my $rep = GT::Analyzers::Report->new( $self );
    $rep->interpret( $filename );
}



############################################################
sub source {
############################################################
  my $self;
  if ( defined($_[0]) && ref($_[0]) =~ /GT::Analyzers::Process/ ) {
    $self = shift;
  } else {
    $self = $myself;
  }

  my $file = shift;
  open F, $file;
  while (<F>) {
    chomp;
    $self->parse( $_ );
  }
  close F;
}

sub DESTROY {
  my $self = shift;
  # Destroy command references
  foreach ( keys %{$self->{'CMDS'}} ) {
    $self->{'CMDS'}{$_} = undef;
  }

  foreach my $key ( keys %{$self->{'config'}} ) {
    undef $self->{'config'}->{$key};
  }
  undef  $self->{'analysis'};
  undef $self->{'calc'}->{'pf'};
  undef $self->{'calc'}->{'first'};
  undef $self->{'calc'}->{'last'};
  undef $self->{'calc'};
  undef $self->{'q'};
  undef $self->{'pf'};
  undef $self->{'pf_manager'};
  undef $self->{'sys_manager'};
  undef $myself;
}

=back

=cut

1;
