use inc::Module::Install;

name     'Finance-GeniusTrader';
all_from 'lib/Finance/GeniusTrader.pm';
author   'Erik Colson <eco@ecocode.net>';
license  'gpl';

test_requires 'Test::More';

no_index directory => 'Windows_Installer';
no_index directory => 'docs';
no_index directory => 'website';

requires 'Date::Calc';
requires 'XML::LibXML';
requires 'Compress::Zlib';

feature 'Charting with GD',
    'GD' => 0;

feature 'Charting with Image::Magick',
    -default => 0,
	'Image::Magick' => 0;

feature 'Charting with SVG',
    -default => 0,
	'SVG' => 0;

feature 'Charting with PostScript',
    -default => 0,
	'PostScript::Simple' => 0;

feature 'HTML Report',
    -default => 0,
	'HTML::Mason' => 0;

feature 'HTTP DB Backend',
    -default => 0,
	'LWP' => 0;

feature 'DBI DB Backend',
    -default => 0,
	'DBI' => 0;

feature 'PostgreSql Backend',
    -default => 0,
	'DBI' => 0,
	'DBD::pg' => 0;

tests 't/*.t t/*/*.t t/*/*/*.t t/*/*/*/*.t t/*/*/*/*/*.t';
author_tests 'xt';

auto_include;
auto_install;

WriteAll;

