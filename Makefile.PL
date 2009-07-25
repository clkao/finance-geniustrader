use inc::Module::Install;

name     'Finance-GeniusTrader';
all_from 'lib/Finance/GeniusTrader.pm';
author   'Erik Colson <eco@ecocode.net>';
license  'gpl';

build_requires 'Test::More';

auto_install;

WriteAll;

