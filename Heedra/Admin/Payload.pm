package Heedra::Admin::Payload;

use strict;
use warnings;
use Heedra::Log;
use Heedra::Utils qw( array_contains );


################################################################################
#
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN
{
  require Exporter;
  @ISA = qw( Exporter );
  my @types    = qw( NOOP REBOOT STATUS STOP TERMINATE );
  my @funcs    = qw( is_valid_admin_message_type       );
  @EXPORT      = qw( );
  @EXPORT_OK   = ( @types, @funcs );
  %EXPORT_TAGS = (
                     all       => [ @EXPORT_OK ],
                     types     => [ @types     ],
                     functions => [ @funcs     ], 
                   );
}
#
################################################################################
#
use constant TYPE => 'type';
use constant
{
  REBOOT    => 'REBOOT',
  STATUS    => 'STATUS',
  STOP      => 'STOP',
  TERMINATE => 'TERMINATE',
};
my @TYPES = ( &REBOOT, &STATUS, &STOP, &TERMINATE );
#
################################################################################


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_admin_message_type #($)#
{
  Trace(Caller(undef, @_));
  my $type = $_[0];
  return (not defined $type) ? 0 : array_contains(\@TYPES, $type);
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


#===============================================================================
#
my $_new = sub #(;$)#  # Called by type-specific constructors below
{
  Trace(Caller('$_new', @_));
  my $invocant = shift;
  my $class    = ref($invocant) || $invocant;
  my $self     = { @_ };
  bless $self, $class;
  return $self;
};
#
#===============================================================================
#
sub Reboot    () { Trace(Caller(undef, @_)); return &new( type => &REBOOT    ) }
sub Status    () { Trace(Caller(undef, @_)); return &new( type => &STATUS    ) }
sub Stop      () { Trace(Caller(undef, @_)); return &new( type => &STOP      ) }
sub Terminate () { Trace(Caller(undef, @_)); return &new( type => &TERMINATE ) }
#
#===============================================================================
#
sub DESTROY {}
#
#===============================================================================


#-------------------------------------------------------------------------------
#
sub is_type #($)#
{
  my $self = shift;
  my $type = $_[0];
  return ( not defined $type    ) ? 0 :
         ( $type eq $self->type ) ? 1 : 0;
}
#
#-------------------------------------------------------------------------------
#
sub type ()
{
  my $self = shift;
  return $self->{ &TYPE };
}
#
#-------------------------------------------------------------------------------


1;
__END__

=head1 NAME

Heedra::???? - ???? for Heedra Queuing System

=head1 SYNOPSIS

  use Heedra::????;
  ????

=head1 DESCRIPTION


=head2 EXPORT

None by default.


=head1 SEE ALSO

Project GitHub Site:

   https://github.com/trevharmon/Heedra

=head1 AUTHOR

Trev Harmon

=head1 COPYRIGHT AND LICENSE

Copyright 2016 Trev Harmon

Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
You may obtain a copy of the License at

   http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
distributed under the License is distributed on an "AS IS" BASIS,
WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
See the License for the specific language governing permissions and
limitations under the License.

=cut

