#!/usr/bin/perl -w

# Copyright 2004 Raphaël Hertzog
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

#
# ras hack rcs tracking: based on version size 6621 dated May 22 2005
# merge with version size 9637 dated Jun 03 2005
#
# $Id$
#

use lib '..';

use strict;
use vars qw($db);

use GT::Prices;
use GT::Calculator;
use GT::Report;
use GT::Conf;
use GT::Eval;
use GT::DateTime;
use Getopt::Long;
use Time::localtime;
use File::Spec;
use Pod::Usage;

use Cwd;

chop (my $prog_name = $0);

GT::Conf::load();

=head1 NAME

manage_portfolio.pl

=head1 SYNOPSIS

  ./manage_portfolio.pl <portfolio> create [<initial-sum>]
  ./manage_portfolio.pl <portfolio> bought <quantity> <share> \
    <price> [ <date> <source> ]
  ./manage_portfolio.pl <portfolio> sold <quantity> <share> \
    <price> [ <date> <source> ]
  ./manage_portfolio.pl <portfolio> stop <share> <price>
  ./manage_portfolio.pl <portfolio> set initial-sum <sum of money>
  ./manage_portfolio.pl <portfolio> set broker <broker>
  ./manage_portfolio.pl <portfolio> report { performance | positions \
   | historic | analysis }
  ./manage_portfolio.pl <portfolio> file <filename>
  ./manage_portfolio.pl <portfolio> db

 where
 <portfolio> is filename of portfolio to use. it can be a non-existent
 file, in which case it will be created

 <quantity> <price> are numeric values for <share> which is the
 appropriate stock symbol or cusip or other identifier

 <date> is optional, the date the transaction happened on. if not
 supplied the default value for 'today' will be supplied. preferred GT
 format for dates is 'YYYY-MM-DD'.

 <source> is optional, a text string, it can be used to note the source
 of the stock transaction. typically an internal GT used field. for
 individual transactions <source> can be set via the --source='string'
 option.

 <broker> name of broker module to use. see ../GT/Brokers/. there is
 no error checking. if the supplied broker module fails to exist the
 portfolio will be flawed.

=head1 OPTIONS

=over

=item --marged

Only useful for "bought" and "sold" commands. It explains that the
corresponding positions are marged, no personal money has been used for
them, the money has been rented.

=item --source <source>

Useful to tag certain orders as the result of a particular strategy. All
orders passed by following the advice of someone could be tagged with
his name and later you'll be able to make stats on the performance you
made with his advices.

=item --template=<template file>

Output is generated using the indicated HTML::Mason component.
For example, when using "report historic" use

  --template="manage_portfolio_historic.mpl"

when using "report positions" use

  --template="manage_portfolio_positions.mpl"

The template directory is defined as Template::directory in the options file.
Each template can be predefined by including it into the options file
For example,

  Template::manage_portfolio_positions manage_portfolio_positions.mpl
  Template::manage_portfolio_historic manage_portfolio_historic.mpl

=item --timeframe { day | week | ... }

Tell how to parse the format of the date.

=item --noconfirm

Do not prompt for confirmation, just apply the request

=item --detailed

Add extra information into the output. On by default. Turn off by using --nodetailed

=item --backup

Make backup of <portfolio> if changes made and applied.
Turn off by using --nobackup.
backup portfolio filename will be <portfolio>.<yyyymmddhhmmss>
where yyyymmddhhmmss is the date-time of the portfolio files'
last modification date and time.

=item --since <date>

=item --until <date>

Those two options are used to restrict the result of a "report" command to
a certain timeframe.

=head1 COMMANDS

=item create

creates <portfolio> and optionally set <initial-sum> available funds.
<initial-sum> is unset if omitted

=item bought <quantity> <share> <price> [<date>]

=item sold <quantity> <share> <price> [<date>]

create a <portfolio> purchase (bought) or sale (sold) transaction

it doesn't appear to support long and short transactions but ...

=item stop <share> <price>

create a stop order for <share> at <price>

=item report { performance | positions | historic | analysis }

generate and output the specified report

=item set { initial-sum | broker } <value>

create and set the value of variables  initial-sum or broker to <value>

=item file <filename>

Specifies the name of a file which contains a list of

bought <quantity> <share> <price> [ <date> <source> ]

and

sold <quantity> <share> <price> [ <date> <source> ]

commands, one per line. This allows you to submit multiple bought/sold
commands in a single instance.

=item db

reads beancounter database portfolio table and creates <portfolio> from it.

negative stock quantities are considered sells, <source> is derived from
the 'type' column. currency is ignored, as GT seems to do.

since the beancounter portfolio really doesn't have necessary
functionality to manage closed positions it is probably best to manage
sells in the GT portfolio using command line or command file features
provided here. in addition, by not introducing negative stock quantities
in the beancounter portfolio table you will also avoid tickling bugs
and messing up the report formats with the unexpected negative quantity
value.

=back

=head1 DESCRIPTION

This tool lets you create a portfolio object on your disk and update it
regularly, this can be used to create virtual portfolio to test how a strategy
works in real time or to track your real portfolio and use GeniusTrader to
make some analysis on it.

The first parameter is a filename of a portfolio. The name is supposed to
be relative to the portfolio directory which is $HOME/.gt/portfolio in
Unix but can be overriden with the configuration item
GT::Portfolio::Directory. If it doesn't exist, it will try in the local
directory.

=head1 BUGS (or maybe just rough edges (in my opinion))

ha! i fixed this next bit

really should be a usage mode, invoked with args -h* | -? | -: and since
the program requires a command, any instantiation without a valid one.

Needs to do a better job of checking input values for bought/sold operations
or
needs to provide a way of completely removing a bad entry

might also be nice to provide a couple of output modes; say one to generate
a file that can used as input for the 
  ./manage_portfolio.pl <portfolio> file <filename>
capability
and one to generate a textualized version of the portfolio, if that makes sense.

=cut

# check for plea for usage
if ( $#ARGV >= 0 && $ARGV[0] =~ /-h|-\?|-:/ ) {
    usage() if ( defined(&usage) );
    exit 0;
}

# check for reasonable number of arguments
if ( $#ARGV <= 0 ) {
    print "$0: both portfolio_name and command are required\n";
    usage() if ( defined(&usage) );
    exit 1;
}

# Get all options
my ($marged, $source, $since, $until, $confirm, $timeframe, $template, $detailed)
 = (0,       '',      '',     '',     1,        'day',      '',        1);
my ($backup) # make makeup of existing portfolio if changes made and applied
 = (1);
my ($verbose) # app gets noisy
 = (0);
GetOptions("marged!" => \$marged, "source=s" => \$source,
	   "since=s" => \$since, "until=s" => \$until,
	   "confirm!" => \$confirm, "timeframe" => \$timeframe,
	   'template=s' => \$template, "detailed!" => \$detailed,
	   "backup!" => \$backup,
	   "verbose+" => \$verbose,
           );

# Check the portfolio directory
#GT::Conf::default("GT::Portfolio::Directory", $ENV{'HOME'} . "/.gt/portfolio");
GT::Conf::default("GT::Portfolio::Directory", GT::Conf::_get_home_path()
 . "/.gt/portfolio");
my $pf_dir = GT::Conf::get("GT::Portfolio::Directory");
mkdir $pf_dir if (! -d $pf_dir);

# Load the portfolio
my $pfname = shift || pod2usage(verbose => 2);
my $cmd = shift || pod2usage(verbose => 2);
my $pf;

if ($pfname !~ m@^(./|/)@) {
    if ( -e "$pf_dir/$pfname" ) {
        $pfname = "$pf_dir/$pfname";
    } elsif ( -e "./$pfname" ) {
        $pfname = "./$pfname";
    }
}
if (-e $pfname) {
    $pf = GT::Portfolio->create_from_file($pfname);
} else {
    $pf = GT::Portfolio->new();
}

my $changes = 0;

# Creation of DB module
my $db = create_db_object();

if ($cmd eq "create") {

    $changes = 1;
#    my $cash = shift || pod2usage(verbose => 2);
    my $cash = shift;
    if (-e $pfname) {
	warn "A portfolio with this name already exists."
         . " The current portfolio will be replaced!\n";
	my $pf = GT::Portfolio->new();
    } else {
	print "Creation of a new portfolio in $pfname...\n";
    }
    if (defined($cash)) {
	print "Setting initial sum to $cash.\n";
	$pf->set_initial_value($cash);
    }

} elsif ( ($cmd eq "bought") or ($cmd eq "sold")
       or ($cmd eq "file") or ($cmd eq "db")) {

    $changes = 1;
    my @orderlist;
    my $batchorder;

    if ($cmd eq "file") {
   	my $file=shift || pod2usage(verbose => 2);
   	# there is a batch file, read it in
   	open(FILE, "<", "$file") || die ("Can not open batch file $file");
		 @orderlist=<FILE>;
    	close(FILE);

    } elsif ($cmd eq "db") {
      print STDERR "\nhello, this is where i'll read the beancounter"
       .           " portfolio table database\nand create a GT equivalent."
       .           "  thing is i'd like to be able to alter the GT"
       .           "\nportfolio by only updating the new positions"
       .           " not necessarily creating\na whole new GT portfolio\n\n"
       .           "yea i thought this was the way it worked -- each subsequent"
       .           " run adds whatever to the current GT portfolio\n"
       .           "\n\n";

      print STDERR "in the alternative we should be able to dump this one"
       .           " and then re-input it so we could maintain it's history\n"
       .           "\n";

      #
      # i made the sql statement an external file so you can easily craft
      # one that suits your needs without having to hack this perl script.
      #
      # the default sql statement will select everything in your beancounter
      # portfolio table except tuples that have a type of 'n/a'.
      # also note on unix at least postgresql (and probably standard sql)
      # considers case significant, so 'N/A' will not be excluded
      #
      open(BC_PORTFOLIO,
       "psql -q -d beancounter -f ./extract_beancounter_portfolio.sql |")
       # the sql yields colon separated values (csv) of
       # $quantity, $code, $price, $date, $source
      || die "could not open input pipe from psql $!/n";
      my @portlist = <BC_PORTFOLIO>;
      close(BC_PORTFOLIO);

      # populate @orderlist from stuff read from db portfolio
      # after a bit of massage and careful kneeding
      foreach $batchorder (@portlist) {
         # separate lines into list
         # prepend "bought" or "sold" depending on qty (postive or negative)
         # ensure $source present even if ""
         my $trans;
         my ( $quantity, $code, $price, $date, $source ) = split /:/, $batchorder;
         $source = "" if ( ! defined($source) );
         ( $quantity > 0 ) ? ( $trans = "bought" ) : ( $trans = "sold" );
         push @orderlist, "$trans $quantity $code $price $date $source";
      }

    } else {
   	# no batch file, place the command line parameters into the
        # start of the data array
        #my ($quantity, $code, $price, $date) = @ARGV;
        my ($quantity, $code, $price, $date, $source) = @ARGV;
   	# for this one off we have to insert the $cmd (bought or sold)
        #$orderlist[0]="$cmd $quantity $code $price $date";
        $orderlist[0]="$cmd $quantity $code $price $date $source";
    }

    foreach $batchorder (@orderlist) {

        chomp($batchorder);
        next if ( $batchorder =~ m/^\s*$/ );
        next if ( $batchorder =~ m/^\s*#/ );
#        my ($cmd, $quantity, $code, $price, $date) = split(/ /,$batchorder);
        my ($cmd, $quantity, $code, $price, $date, $source) =
         split(/\s+/,$batchorder);
print STDERR "batch line\n"
 . "cmd=$cmd, quantity=$quantity, code=$code, price=$price,"
 . " date=$date, source=$source\n" if ( $verbose > 1 );
        if (! defined($date)) {
            $date = sprintf("%04d-%02d-%02d",
             localtime->year + 1900, localtime->mon + 1, localtime->mday);
        }
        if ( $date =~ m@/@ ) {
          # fix me
          # hack in date conversion -- i like date::manip
          die "come on -- gt only likes dates formatted yyyy-mm-dd\n"
          .   "i'm not going accept \"$date\", nor will i convert it, sorry (not).\n";
        }

        my $order = GT::Portfolio::Order->new;
#        if ($cmd eq "bought") {
        if ( $cmd =~ m/bought|buy/i ) {
            $order->set_buy_order;
        } elsif ( $cmd =~ m/sold|sell/i ) {
            $order->set_sell_order;
        } else {
            die "sorry -- i don't recognize $cmd in \"$batchorder\"\n";
        }
        $order->set_type_limited;
        $order->set_price($price);
        $order->set_submission_date($date);
        $order->set_quantity($quantity);
        $order->set_source($source) if ($source);

        my $name = $db->get_name($code);
        # Look for open positions to complete
        my $pos = find_position($pf, $code, $source, $marged);
        if (! defined $pos) {
            if (defined($name) && $name) {
                print "Creating a new position ($name - $code, $source).\n";
            } else {
                print "Creating a new position ($code, $source).\n";
            }

            $pos = $pf->new_position($code, $source, $date);
            $pos->set_timeframe(GT::DateTime::name_to_timeframe($timeframe));
            # here is the only place one can make a distinction between
            # long and short orders/positions
            # but the only distinction(s) being considered is(are) $marged
            if ($marged) {
                $pos->set_marged();
            } else {
                $pos->set_not_marged();
            }
        }
        print "Applying order: $cmd $code $quantity at $price on $date";
        $pf->apply_order_on_position($pos, $order, $price, $date);
        print " done.\n";

        # store the portfolio evaluation for the given date
        print "eval portfolio for $date";
        $pf->store_evaluation($date);
        print " done.\n";
    }

} elsif ($cmd eq "stop") {

    my ($code, $price) = @ARGV;
    my $name = $db->get_name($code);

    my $pos = find_position($pf, $code, $source, $marged);
    if (! defined($pos)) {
	print "No corresponding open positions found.\n";
    } else {
	$changes = 1;
	$pos->force_stop($price);
	if (defined($name) && $name) {
	    print "Setting the stop level of $name - $code to $price.\n";
	} else {
	    print "Setting the stop level of $code to $price.\n";
	}
    }

} elsif ($cmd eq "set") {

    $changes = 1;
    my ($var, $value) = @ARGV;
    if ($var eq "initial-sum") {
	print "Setting initial sum to $value.\n";
	$pf->set_initial_value($value);
    } elsif ($var eq "broker") {
	print "Setting broker to $value.\n";
	my $broker = create_standard_object("Brokers::$value");
	$pf->set_broker($broker);
    }

} elsif ($cmd eq "split") {

    #
    # split required arguments: code and split ratio (post:pre)
    #
    my ($code, $ratio) = @ARGV;
    my $sf;

    if ( ! $code ) {
        print "$prog_name: error: symbol required\n";
        print "\nexample $prog_name bc_pf split POT 3:1";
        exit 1;
    }
    if ( $ratio =~ /\d+\s*:\s*\d+/ ) {
        my ($post, $pre) = split /:/, $ratio;
        $sf = $post / $pre;
    } else {
        print "$prog_name: error: split ratio required\n";
        print "\nexample $prog_name bc_pf split POT 3:1";
        exit 1;
    }
    #
    # for each position involving $code
    #
    foreach my $pos ( $pf->list_open_positions() ) {
        if ( $pos->{'code'} eq $code ) {
            my ( $piq, $pq, $pop, $oq, $op );
            $changes = 1;

            $piq = $pos->{'initial_quantity'};
            $pos->{'initial_quantity'} = $piq * $sf;

            $pq = $pos->{'quantity'};
            $pos->{'quantity'} = $pq * $sf;

            $pop = $pos->{'open_price'};
            $pos->{'open_price'} = sprintf("%.6f", $pop / $sf);

            if ( $verbose ) {
                print "splitting $pos->{'code'} position:\n";
                print "  initial quantity: was $piq, now $pos->{'initial_quantity'}\n";
                print "  quantity: was $pq, now $pos->{'quantity'}\n";
                print "  position price: was $pop, now $pos->{'open_price'}\n";
            }
            foreach my $order ( @{$pos->{'details'}} ) {
                $oq = $order->{'quantity'};
                $order->{'quantity'} = $oq * $sf;

                $op = $order->{'price'};
                $order->{'price'} = sprintf("%.6f", $op / $sf);

                if ( $verbose ) {
                    print "splitting $pos->{'code'} order:\n";
                    print "  quantity: was $oq, now $order->{'quantity'}\n";
                    print "  position price: was $op, now $order->{'price'}\n";
                }
            }
        }
    }

} elsif ($cmd eq "report") {

    my ($what) = @ARGV;
    unless ( $what ) {
      print STDERR "need to know what to report\n"
       . "(e.g. performance | positions | historic | analysis\n";
      usage() if ( defined(&usage) );
      exit 1;
    }

    # code for templating setup
    my $root = GT::Conf::get('Template::directory');
    $root = File::Spec->rel2abs(cwd()) if (!defined($root));

    # try and get the template from the config file if it has not been
    # defined on the command line
    # the template name in the config file is expected to be
    # manage_portfolio_$what
    # with $what designating the type of report being selected

    unless ( ! $template gt '' ) {
      $template = GT::Conf::get("Template::manage_portfolio_$what")
       if ($template eq '');
    } else {
      $template = '';
print STDERR "not using template\n";
    }

    my $db = create_db_object();

    if ($template eq '') {
        # no template is defined either on the command line
        # or in the config file
        # use Report.pm for standard reporting
        if ($what eq "performance" || $what =~ m/pe.*/i ) {
            print "\n$0: sorry performance not yet implemented\n";

        } elsif ( $what eq "positions" || $what =~ m/po.*/i ) {
	    GT::Report::OpenPositions($pf, $detailed);

        } elsif ( $what eq "historic" || $what =~ m/hi.*/i ) {
            GT::Report::Portfolio($pf, $detailed)
             || print "\ndidn't find any history in the portfolio\n";

        } elsif ( $what eq "analysis" || $what =~ m/an.*/i ) {
	    print "\n$0: sorry analysis not yet implemented\n";
	    print "\nhumm, well, not so fast there grasshopper\n"
             . "-- here we have hacked in a call to\n"
	     . "GT::Report::SimplePortfolioAnalysis(...)\n\n";
            GT::Report::SimplePortfolioAnalysis($pf->real_global_analysis);
            print "\n\nbut as you can see it don't do very much\n";

            print "\ntrial and error poking on this stuff suggests that\n";
            print "a portfolio cannot be analyzed without a history, and\n";
            print "you ain't got no history unless a position is closed.\n";
            print "seems odd to me, but that methinks is the way it works.\n";

            my ($sec, $min, $hour, $d, $m, $y, $wd, $yd) = localtime();
            my $today = sprintf("%04d-%02d-%02d", $y+1900, $m+1, $d);
            if ( $pf->has_historic_evaluation("$today") ) {
              GT::Report::SimplePortfolioAnalysis($pf->real_global_analysis);
              # following one divides by zero, without a history in portfolio
              GT::Report::PortfolioAnalysis($pf->real_global_analysis, $detailed);
            } else {
              print "\ndon't see no stinkin' history in your portfolio man!\n";
              print "you got not stinkin' history, you get no stinkin' analysis!\n";
              print "\n\n";
              print "on the other hand we could be nice and artifically close\n";
              print "everthing today, run the analyses and leave, but that's\n";
              print "just too bloody polite, if you ask me!\n";
              print "\nif you're interested see the bit near the comment\n";
              print "# Close the open positions in sub backtest_single ../GT/BackTest.pm\n";
              print "\n\n";
              
              print "\n\n";
            }

#             # lets try GT::Report::PortfolioAnalysis($pf, $detailed)
# 	      print "\nwell, ok -- here we have hacked in a call to\n"
# 	       . "GT::Report::PortfolioAnalysis($pf->real_global_analysis, $detailed)\n\n";
#             GT::Report::PortfolioAnalysis($pf->real_global_analysis, $detailed);
#             print "\n\nbut as you can see it don't work so good!\n";
#             print "\n\n---\n\n";
# 
#             print "\n\n real_analysis_by_code T \n\n";
#             GT::Report::PortfolioAnalysis($pf->real_analysis_by_code, "T");
#             print "\n\n---\n\n";
            
        } else {
            print "\n$0: unknown report type \"$what\"\n";
        }
    } else {
        # template reporting using HTML::Mason is being invoked
        my $output;
        my $use = 'use HTML::Mason;use File::Spec;use Cwd;';

        eval $use;
        die(@!) if(@!);

        my $interp = HTML::Mason::Interp->new( comp_root => $root,
    					       out_method => \$output
    				             );
        $template='/' . $template unless ($template =~ /\\|\//);
        $interp->exec($template, detailed => $detailed, p => $pf, db => $db);
        print $output;
    }

} else {

    print "$0: Invalid command \"${cmd}\"\n";
    usage() if ( defined(&usage) );
    exit 1;
}

if ($changes) {
    local $| = 1;
    my $is_confirmed = $confirm ? 0 : 1;
    if ($confirm) {
	print "\n-- Do you confirm all the above operations ? [y]n ";
	my $ans = <STDIN>;
	chomp($ans);
	if ($ans =~ /^(y|)$/i) {
	    print "Applying all the planned changes !\n";
	    $is_confirmed = 1;
	} else {
	    print "Discarding all the planned changes !\n";
	    $is_confirmed = 0;
	}
    }
    if ($is_confirmed) {
	print "Storing changes ... ";
        if ( $backup && -e $pfname ) {
          print "creating backup ";
          use File::Copy qw( mv );
          use POSIX qw( strftime );
          # create backup portfolio filename
          my $ext = strftime( "%Y%m%d%H%M%S",
           POSIX::localtime( (POSIX::stat("$pfname"))[9] )
          );
          if ( ( mv "$pfname", "$pfname.$ext" ) == 1 ) {
            print "ok file name is $pfname.$ext ";
          }else{
            print "\noh no! the rename failed. $!\n";
          }
        }
	$pf->store($pfname);
	print "done.\n";
    }
}

$db->disconnect;


sub find_position {
    my ($pf, $code, $source, $marged) = @_;
    my $pos;
    foreach ($pf->get_position($code, $source)) {
	next if (! defined($_));
	if ($marged) {
	   $pos = $_ if ($_->is_marged);
	} else {
	   $pos = $_ if (! $_->is_marged);
	}
    }
    return $pos;
}


sub usage {
  print "$0 <portfolio_name> <cmd> [ options ] [ arguments ]\n";
  print "\n";
  print "  where <portfolio_name> is the pathname to a gt portfolio file\n";
  print "        <cmd> is one of:\n";
  print "        create [ <initial-sum> ]\n";
  print "        bought <args> | sold <args> | file <filename> | db\n";
  print "        report { per | pos | his | ana } \n";
  print "        set { initial-sum | broker } <value>\n";
  print "        stop <ticker-symbol> <stop-price>\n";
  print "        split <ticker-symbol> <post : pre>\n";
  print "\n";
  print "options can appear anywhere on the command line. some may not be\n";
  print "applicable to all commands.\n";
  print "  --marged --nomarged        (off) borrowed funds used (not used) for position\n";
  print "  --confirm --noconfirm      (on)  ask (don't ask) for input confirmation\n";
  print "  --detailed --nodetailed    (on)  include extra info on output\n";
  print "  --since <date>             ('')  report since <date>\n";
  print "  --until <date>             ('')  report until <date>\n";
  print "  --source <source>          ('')  tag order as result of a GT strategy\n";
  print "  --template=<template file> ('')  format per HTML::Mason template\n";
  print "  --timeframe {day|week|...} (day) date format\n";
  print "  --backup --nobackup        (on)  make (don't make) backup of portfolio\n";
  print "  --verbose                  (off) app gets noisy\n";
  print "\n";
  print "    db command will attempt to use psql to read beancounter portfolio table\n";
  print "    creating (or adding positions therein) to this GT portfolio\n";
  print "    positions are considered 'bought' if qty > 0 otherwise a 'sold'\n";
  print "\n";
  print "    marged option is not well supported except for individually added\n";
  print "    positions. in addition, it isn't clear if these positions are all\n";
  print "    long, since there seems to be no distinction in this code.\n";
  print "\n";
  print "arguments include\n";
  print "    all arguments to describe a transaction (via 'bought'|'sold' cmds)\n";
  print "    filename of bought|sold records (via file cmd)\n";
  print "    symbol and price used by stop cmd\n";
  print "    filename of output reporting template (via report cmd)\n";
  print "    cash amount to initialize a new portfolio (via create cmd)\n";
  print "    variable ('initial-sum'|'broker') and value used by set cmd\n";
  print "\n";
  print "  bought|sold records are white space separated, formatted as follows:\n";
  print "    <'bought'|'sold'> <quantity> <symbol> <price> [<date>] [<source>]\n";
  print "    note: no validation or sanity checks are performed on these arguments\n";  
  print "    note: <date> on command line over-ridden if in data file\n";  
  print "    note: <source> on command line over-ridden if in data file\n";  
  print "\n";
  print "  report arguments { performance | positions | historic | analysis }\n";
  print "    unique abbreviations are fine (e.g. pe == performance, po == positions\n";
  print "    as of this writing 'performance' and 'analysis' are no-ops\n";
  print "    and 'historic' didn't seem to do much (because my ports don't have\n";
  print "    any history records and i can't seem to figure out how to create them (yet)\n";
  print "\n";
  print "  <template file> allow user to customize the report output\n";
  print "  you will need to have both a Templates directory and templates for\n";
  print "  each type of report (e.g. performance, positions, ...)\n";
  print "\n";
  print "  NB as of now these strings must match report arguments used exactly\n";
  print "\n";
  print "  template files should stored be in the Templates dir and can be set\n";
  print "  via your .gt/options file using this key format:\n";
  print "    Template::manage_portfolio_<report_type>, where <report_type> is\n";
  print "    one of the report arguments\n";
  print "\n";
  print "  in addition template files can be either mpl or mhtml type files\n";
  print "  see perldoc HTML::Mason for details\n";
  print "\n";
  print "for gory details try 'perldoc $0'\n";
  print "\n";
  
}

exit;

#
# to implement a split feature of a portfolio holding
#
# what happens if you've got a short position and the company
# does a split -- does the position size get split too?
# you borrowed and sold presplit sized shares so i'd guess you'd need
# to replace the equivalent sized shares
#
# 1) applies only to current orders and positions -- closed positions don't count
# 2) GT::Portfolio::Position
#    position initial_quantity
#    position open_price
#    position quantity
#    
# 3) GT::Portfolio::Order
#    order price
#    order quantity
#    
#

# } elsif ($cmd eq "split") {
#   my $eval = "true";
#   #
#   # split requires code and split ratio (post:pre)
#   #
#   my ($code, $ratio) = @ARGV;
#
#   if ( ! $code ) {
#     print "$prog_name: error: symbol required\n";
#     print "\nexample $prog_name bc_pf split POT 3:1";
#     exit 1;
#   }
#   if ( $ratio =~ /\d+\s*:\s*\d+/ ) {
#     my ($post, $pre) = split /:/ $ratio;
#     my $sf = $post / $pre;
#   } else {
#     print "$prog_name: error: split ratio required\n";
#     print "\nexample $prog_name bc_pf split POT 3:1";
#     exit 1;
#   }
#   #
#   # for each position involving $code
#   #
#   foreach my $pos ( $p->list_open_positions() ) {
#     if ( $pos->{'code'} eq $code ) {
#       if ( ! $eval ) {
#         $pos->{'initial_quantity'} = $pos->{'initial_quantity'} * $sf;
#         $pos->{'quantity'}         = $pos->{'quantity'} * $sf;
#         $pos->{'open_price'}       = sprintf "%.6f", $pos->{'open_price'} / $sf;
#         foreach my $ord ( @{$pos->{'details'}} ) {
#           $ord->{'quantity'} = $ord->{'quantity'} * $sf;
#           $ord->{'price'}    = sprintf "%.6f", $ord->{'price'} / $sf;
#         }
#       } else {
#         print "code = $pos->{'code'}\n";
#         print "iqty = $pos->{'initial_quantity'} * $sf, ";
#         print "qty  = $pos->{'quantity'} * $sf, ";
#         print "oprc = $pos->{'open_price'} / $sf\n";
#         foreach my $ord ( @{$pos->{'details'}} ) {
#           print "qty   = $ord->{'quantity'} * $sf, ";
#           print "price = sprintf "%.6f", $ord->{'price'} / $sf\n";
#         }
#         print "\n";
#       }
#     }
#   }
