#!/usr/bin/perl -w

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use lib '..';

use strict;

use GT::Report;
use GT::Conf;
use GT::BackTest::Spool;
use Getopt::Long;

GT::Conf::load();

my $set = '';
GetOptions("set=s" => \$set);

my $outputdir = shift;
$outputdir = GT::Conf::get("BackTest::Directory") if (! $outputdir);
$outputdir = "." if (! $outputdir);

my $spool = GT::BackTest::Spool->new($outputdir);

GT::Report::AnalysisList($spool, $set);

