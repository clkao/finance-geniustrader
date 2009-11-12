package Finance::GeniusTrader::CLI;

use Finance::GeniusTrader::DateTime;
use Finance::GeniusTrader::Eval;
use Finance::GeniusTrader::Tools qw(:conf :timeframe);
use Finance::GeniusTrader::Calculator;
use Finance::GeniusTrader::Conf;
use Getopt::Long;

sub init {
    my @getopt_extra = @_;

    Finance::GeniusTrader::Conf::load();

    my $nb_item = Finance::GeniusTrader::Conf::get('Option::nb-item');
    my ($full, $start, $end, $timeframe, $max_loaded_items) =
        (0, '', '', 'day', -1);
    my $man = 0;
    my @options;
    Getopt::Long::Configure("require_order");
    GetOptions('full!' => \$full, 'nb-item=i' => \$nb_item, 
               "start=s" => \$start, "end=s" => \$end, 
               "max-loaded-items=s" => \$max_loaded_items,
               "timeframe=s" => \$timeframe,
               "option=s" => \@options, "help!" => \$man, @getopt_extra);

    $nb_item = ( defined($nb_item) || $full ) ? $nb_item : 200;
    $timeframe = Finance::GeniusTrader::DateTime::name_to_timeframe($timeframe);

    check_dates($timeframe, $start, $end);

    my $db = create_db_object();
    return sub {
        my $code = shift;
        find_calculator($db, $code, $timeframe, $full, $start, $end, $nb_item, $max_loaded_items);
    }

}

1;
