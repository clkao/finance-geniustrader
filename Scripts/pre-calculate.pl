use lib '..';

use strict;
use GT::Prices;
use GT::Calculator;
use GT::Eval;
use Getopt::Long;
use GT::DateTime;
use GT::CLI;
use GT::Tools qw(:timeframe);
use File::Path 'mkpath';
use Digest::SHA1  qw(sha1_hex);

my $init = GT::CLI::init();
my $code = shift || pod2usage(verbose => 2);
my ($calc, $first, $last) = $init->($code);
die "must use --full" if $first  != 0;

my $dir = GT::Conf::get("DB::text::directory");

my $timeframe_name = GT::DateTime::name_of_timeframe($calc->current_timeframe);

while (<DATA>) {
    chomp;
    my ($name, $spec) = split(',', $_, 2);
    my $pdir = "$dir/$code/$timeframe_name";
    mkpath [$pdir];

    my ($mod, $arg) = split(/ /, $spec, 2);
    my $indicator = create_standard_object($mod, $arg);
    my $standard_name = get_standard_name($indicator);
    my ($short) = $standard_name =~ m/[\S:](\w+)\s/;
    my $file = "$pdir/$short.".sha1_hex($standard_name).".i";
    print "$name ... $spec..$file\n";
    # XXX: check timestamp ?
    next if -e $file;

    open my $fh, '>', $file or die $!;
    my $nth = $mod =~ m#/(\d+)# ? $1-1 : 0;
    my $i_name = $indicator->get_name($nth);
    print "... $nth $i_name\n";
    $indicator->calculate_interval($calc, 0, $calc->prices->count-1);

    for my $i (0..$calc->prices->count-1) {
        my @vals;
        for my $name (map { $indicator->get_name($_) } 0..$indicator->get_nb_values-1) {
            my $val = $calc->indicators->get($name, $i);
            $val = 'NA' unless length $val;
            push @vals, $val;
        }
        print $fh join(",",@vals).$/;
    }
}

__DATA__
ma20,I:SMA 20
adx60,I:ADX 60
adx30,I:ADX 30
adx15,I:ADX 15
MA5,I:SMA 5
