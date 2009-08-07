#!perl -T

use strict;
use warnings;
use Test::More;
use File::Spec;

# Only run this tests if environment var TEST_AUTHOR is set
plan skip_all => 'Author test.  Set $ENV{TEST_AUTHOR} to true to run.'
  if (not $ENV{TEST_AUTHOR}) ;

eval "require Test::Perl::Critic";

plan skip_all => 'Test::Perl::Critic required for test.' if ($@);

Test::Perl::Critic->import();
all_critic_ok();
