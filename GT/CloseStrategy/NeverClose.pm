package GT::CloseStrategy::NeverClose;

# Copyright 2000-2002 Raphaël Hertzog, Fabien Fulhaber
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

# Standards-Version: 1.0

use strict;
use vars qw(@ISA @NAMES);

use GT::CloseStrategy;

@ISA = qw(GT::CloseStrategy);
@NAMES = ("NeverClose");

=head1 GT::CloseStrategy::NeverClose

This strategy never close the already opened positions. This is very
usefull to design a sort of Multiple Buy & Hold or Multiple Sell & Hold
strategies.

=cut

sub long_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub short_position_opened {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub manage_long_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;

    return;
}

sub manage_short_position {
    my ($self, $calc, $i, $position, $pf_manager, $sys_manager) = @_;
    
    return;
}

