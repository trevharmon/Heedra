package Heedra::Blender::Payload;

use strict;
use warnings;
use Heedra::Blender::Job;
use Heedra::Log;


################################################################################
#
my ($_init);
$Carp::Internal{ (__PACKAGE__) }++;
#
################################################################################
#
use constant
{
  JOB         => 'job',
  END_FRAME   => 'end_frame',
  START_FRAME => 'start_frame',
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
  my $self     = { @_ };
  bless $self, $class;
  return $self->$_init(@_);
};
#
#===============================================================================
#
$_init = sub #(%)#
{

  Trace(Caller('$_init', @_));
  my $self = shift;
  my %data = @_;

  # Clear Data Structures
  $self->{ &JOB         } = undef;
  $self->{ &END_FRAME   } = undef;
  $self->{ &START_FRAME } = undef;

  # Set Provided Data
  if ( exists($data{&JOB}) and
       not $self->set_job($data{&JOB}) )
  {
    Error('Invalid Job Definition');
    return undef;
  }
  if ( exists($data{&END_FRAME}) and
       not $self->set_end_frame($data{&END_FRAME}) )
  {
    Error('Invalid End Frame');
    return undef;
  }
  if ( exists($data{&START_FRAME}) and
       not $self->set_start_frame($data{&START_FRAME}) )
  {
    Error('Invalid Start Frame');
    return undef;
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
sub job () { Trace(Caller(undef, @_)); return $_[0]->{ &JOB } }
#
#-------------------------------------------------------------------------------
#
sub get_job         () { Trace(Caller(undef, @_)); return $_[0]->{ &JOB         } }
sub get_end_frame   () { Trace(Caller(undef, @_)); return $_[0]->{ &END_FRAME   } }
sub get_start_frame () { Trace(Caller(undef, @_)); return $_[0]->{ &START_FRAME } }
#
#-------------------------------------------------------------------------------
#
sub set_job #($)#
{

  Trace(Caller(undef, @_));
  my $self = shift;
  my $data = $_[0];

  return 0 if not defined $data
           or 'Heedra::Blender::Job' ne ref $data;
  $self->{&JOB} = $data;

  return 1;

}
#
#-------------------------------------------------------------------------------
#
sub set_end_frame #($)#
{

  Trace(Caller(undef, @_));
  my $self = shift;
  my $data = $_[0];

  return 0 if not defined $data
           or $data !~ /^\d+$/;
  $self->{&END_FRAME} = $data;

  return 1;

}
#
#-------------------------------------------------------------------------------
#
sub set_start_frame #($)#
{

  Trace(Caller(undef, @_));
  my $self = shift;
  my $data = $_[0];

  return 0 if not defined $data
           or $data !~ /^\d+$/;
  $self->{&START_FRAME} = $data;

  return 1;

}
#
#-------------------------------------------------------------------------------


1;
__END__

d1 NAME

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

