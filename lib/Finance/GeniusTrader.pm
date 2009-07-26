package Finance::GeniusTrader;

use warnings;
use strict;

use vars qw/$VERSION/;

=head1 NAME

Finance::GeniusTrader - a full featured toolbox to create trading systems

=head1 VERSION

Version 0.00_50

=cut

our $VERSION = '0.00_50';


=head1 DESCRIPTION

GeniusTrader aims to be a full featured toolbox to create trading systems. Powerful systematic trading requires several things :

=over

=item * many indicators and corresponding signals

=item * money management rules

=item * deciding what is a reasonable amount of money to put on a single trade (to limit the risk associated to that trade)

=item * combining different values within the portfolio (to limit the global risk)

=item * flexibility to be able to test all combinations with the above items

=item * backtesting system with analysis of results

=back

GeniusTrader already has support of most of this. GeniusTrader consists of a bunch of perl modules associated to a few perl scripts. It has no graphical user interface since it's absolutely not needed to achieve its goals ...

=head1 SYNOPSYS

Please read submodules synopsis for usage.

=head1 AUTHOR

Erik Colson, C<< <eco at ecocode.net> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-finance-geniustrader at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Finance-GeniusTrader>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Finance::GeniusTrader


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Finance-GeniusTrader>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Finance-GeniusTrader>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Finance-GeniusTrader>

=item * Search CPAN

L<http://search.cpan.org/dist/Finance-GeniusTrader/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 COPYRIGHT & LICENSE

=over

=item - Copyright 2009 Erik Colson

=item - Copyright 2008 Thomas Weigert

=item - Copyright 2008 Robert A. Schmied

=item - Copyright 2005 João Costa

=item - Copyright 2004 Oliver Bossert

=item - Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber

=back

This program is released under the following license: gpl v2

=cut

1; # End of Finance::GeniusTrader
