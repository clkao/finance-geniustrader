use inc::Module::Install;

name     'Finance-GeniusTrader';
all_from 'lib/Finance/GeniusTrader.pm';
author   'Erik Colson <eco@ecocode.net>';
license  'gpl';

test_requires 'Test::More';

no_index directory => 'Windows_Installer';
no_index directory => 'docs';
no_index directory => 'website';

WriteAll;

