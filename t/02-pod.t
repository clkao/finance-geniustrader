#!perl -T

use strict;
use warnings;
use Test::More;

# Only run this tests if environment var TEST_AUTHOR is set
plan skip_all => 'Author test.  Set $ENV{TEST_AUTHOR} to true to run.'
  if (not $ENV{TEST_AUTHOR}) ;

# Ensure a recent version of Test::Pod
my $min_tp = 1.22;
eval "use Test::Pod $min_tp";
plan skip_all => "Test::Pod $min_tp required for testing POD" if $@;

all_pod_files_ok();
