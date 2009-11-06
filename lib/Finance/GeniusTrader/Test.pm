package Finance::GeniusTrader::Test;
use strict;
use warnings;
use base 'Test::More';
use FindBin;
use File::Temp;
use Finance::GeniusTrader::Conf ();
use Finance::GeniusTrader::Eval ();
our @EXPORT = qw(play_prices_until);

=head1 NAME

Finance::GeniusTrader::Test - Test helpers for Finance::GeniusTrader

=head1 SYNOPSIS

  use Finance::GeniusTrader::Test
    tests => 1,
    gt_config => sub {
        my $test_base = shift;
        my $db_path = File::Spec->catdir($test_base, 'data');
        return "DB::module Text\nDB::text::directory $db_path\n"
    };

    my ($calc, $first, $last) = Finance::GeniusTrader::Tools::find_calculator(Finance::GeniusTrader::Test->gt_db, 'TX', $PERIOD_5MIN, 1)
    ok($calc);

=head1 DESCRIPTION

This module provides helper functions for writing GT tests.

=cut

my ($gt_options, $gt_db);
sub import_extra {
    my ($class, $args) = @_;

    $class->setup(@$args);
    Test::More->export_to_level(2);
}

sub setup {
    my ($class, %args) = @_;
    my ($test_base) = $FindBin::Bin =~ m{(.*/t/)};
    my $dir = File::Spec->catdir($test_base, 'data');
    $class->prepare_gt_conf($dir, $args{gt_config}->($test_base));
    Finance::GeniusTrader::Conf::load($class->gt_options);
    return;
}

sub gt_options {
    my ($class) = @_;
    $gt_options ||= File::Temp->new;
}

sub gt_db {
    $gt_db ||= Finance::GeniusTrader::Eval::create_db_object();
}

sub prepare_gt_conf {
    my ($self, $db_path, $gt_config) = @_;
    open my $fh, '>', $self->gt_options or die $!;
    print $fh $gt_config;
}

1;
