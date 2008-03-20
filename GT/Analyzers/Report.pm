package GT::Analyzers::Report;

# Copyright 2004 Oliver Bossert
# This file is distributed under the terms of the General Public License
# version 2 or (at your option) any later version.

use strict;

use GT::Analyzers::Process;

use Cwd;
use File::Spec;
use HTML::Mason;

=head1 NAME

GT::Analyzers Report

=head2 DESCRIPTION

This module is mainly a wrapper to process a report file with
HTML::Mason.

This module needs HTML::Mason to display the reports and
Cwd and File::Spec to find out the actual path.

=cut

############################################################
sub new { # Generate a new Object
############################################################
  my $type = shift;
  my $class = ref($type) || $type;
  my $self = {};
  bless $self, $class;

  my $proc = shift;
  if ( defined($proc) && ref($proc) =~ /Process/ ) {
      $self->{'proc'} = $proc;
  } else {
      $self->{'proc'} = GT::Analyzers::Process->new();
  }
  return $self;
}


############################################################
sub interpret {
############################################################
  my $self = shift;
  my $filename = shift;
  my @commands = @_;
  my $output;
  my $root = File::Spec->rel2abs( cwd() );
  my $interp = HTML::Mason::Interp->new( comp_root => $root,
					 out_method => \$output
				       );

  foreach ( @commands ) {
    print STDERR $self->{'proc'}->parse( $_ );
  }

  $interp->exec( '/' . $filename,
		 proc => $self->{'proc'} );

  return $output;
}

1;
