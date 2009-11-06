#!perl -T

use strict;
use warnings;
use Test::More;
use File::Spec;

eval "require Test::Perl::Critic";

plan skip_all => 'Test::Perl::Critic required for test.' if ($@);

Test::Perl::Critic->import();
all_critic_ok();
