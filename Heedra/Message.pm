package Heedra::Message;

use strict;
use warnings;
use Heedra::Header;
use Heedra::Log;


################################################################################
#
my ($_init);
#
################################################################################
#
our $PACKAGE = __PACKAGE__;
use constant
{
  HEADER      => 'header',
  HEADER_TYPE => 'Heedra::Header',
  PAYLOAD     => 'payload',
};
#
################################################################################


#===============================================================================
#
sub new #(%)#
{
  Trace(Caller(undef, @_));
  my $invocant = shift;
  my $class    = ref($invocant) || $invocant;
  my $self     = {};
  bless $self, $class;
  return $self->$_init(@_);
}
#
#===============================================================================
#
$_init = sub #(%)#
{

  Trace(Caller('$_init', @_));
  my $self = shift;
  my %data = @_;

  # Build Data Structures
  $self->{ &HEADER  } = undef;
  $self->{ &PAYLOAD } = undef;

  # Set Provided Data
  if (exists $data{&HEADER})
  {
    if (not $self->set_header($data{&HEADER}))
    {
      Error('Invalid ' . &HEADER . " for $PACKAGE creation");
      return undef;
    }
  }
  else
  {
    $self->set_header(Heedra::Header->new);
  }
  if (exists $data{&PAYLOAD})
  {
    if (not $self->set_payload($data{&PAYLOAD}))
    {
      Error('Invalid ' . PAYLOAD . " for $PACKAGE creation");
      return undef;
    }
  }

  return $self;

};
#
#===============================================================================
#
sub DESTROY {}
#
#===============================================================================


#-------------------------------------------------------------------------------
#
sub execute ()
{
  Trace(Caller(undef, @_));
  my $self = shift;
  my $rc   = $self->payload->execute;
  if (not $rc)
  {
    Error( 'Failed to execute payload for message #' .
            $self->header->get_message_id );
    return 0;
  }
  return 1;
}
#
#-------------------------------------------------------------------------------
#
sub header ()
{
  Trace(Caller(undef, @_));
  my $self = shift;
  return (defined $self->{&HEADER}) ? $self->{&HEADER} : undef;
}
#
#-------------------------------------------------------------------------------
#
sub payload ()
{
  Trace(Caller(undef, @_));
  my $self = shift;
  return (defined $self->{&PAYLOAD}) ? $self->{&PAYLOAD} : undef;
}
#
#-------------------------------------------------------------------------------
#
sub type ()
{
  Trace(Caller(undef, @_));
  my $self = shift;
  return $self->header->get_type;
}
#
#-------------------------------------------------------------------------------
#
sub get_header  () { Trace(Caller(undef, @_)); return $_[0]->header  }
sub get_payload () { Trace(Caller(undef, @_)); return $_[0]->payload }
sub get_type    () { Trace(Caller(undef, @_)); return $_[0]->type    }
#
#-------------------------------------------------------------------------------
#
sub set_header #($)#
{
  Trace(Caller(undef, @_));
  my $self = shift;
  my $obj  = $_[0];
  return 0 unless defined($obj)
              and HEADER_TYPE eq ref $obj;
  $self->{&HEADER} = $obj;
  return 1;
}
#
#-------------------------------------------------------------------------------
#
sub set_payload #($)#
{
  Trace(Caller(undef, @_));
  my $self = shift;
  my $obj  = $_[0];
  return 0 unless defined $obj;
  $self->{&PAYLOAD} = $obj;
  $self->header->set_type(ref $obj);
  return 1;
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

