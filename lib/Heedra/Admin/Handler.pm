package Heedra::Admin::Handler;

use strict;
use warnings;
use Heedra::Admin::Payload qw( :all );
use Heedra::Log;
use Time::HiRes qw( ); # Don't import anything


################################################################################
#
my ($_init);
$Carp::Internal{ (__PACKAGE__)}++;
#
################################################################################
#
use constant
{
  ACTION        => 'action',
  END_END       => 'end_time',
  OUTPUT_STDERR => 'stderr',
  OUTPUT_STDOUT => 'stdout',
  START_TIME    => 'start_time',
};
#
################################################################################


#===============================================================================
#
sub new #($)#
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
$_init = sub #($)#
{

  Trace(Caller('$_init', @_));
  my $self    = shift;
  my $payload = $_[0];
  my $config  = $_[1];

  if (not defined $payload)
  {
    Fatal('Missing Payload for ' . __PACKAGE__ . ' (handler)');
    return undef;
  }
  if (not 'Heeda::Admin::Payload' eq ref $payload)
  {
    Fatal('Invalid Payload for ' . __PACKAGE__ . ' (handler)');
    return undef;
  }

  $self->{ &ACTION        } = $payload->type;
  $self->{ &OUTPUT_STDERR } = undef;
  $self->{ &OUTPUT_STDOUT } = undef;
  $self->{ &START_TIME    } = undef;
  $self->{ &END_TIME      } = undef;

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

  $self->start_time = Time::HiRes::time;

  if    ( REBOOT    eq $self->{&ACTION} ) #                   ---   REBOOT   ---
  {
    `shutdown -r now`;
  }
  elsif ( STATUS    eq $self->{&ACTION} ) #                   ---   STATUS   ---
  {
    # TODO Implement
  }
  elsif ( STOP      eq $self->{&ACTION} ) #                   ---    STOP    ---
  {
    exit; #TODO determine best exit code
  }
  elsif ( TERMINATE eq $self->{&ACTION} ) #                   --- TERMINATE  ---
  {
    `shutdown -h now`;
  }
  else
  {
    Fatal('Unknown Action Type for ' . __PACKAGE__ . ' (handler)');
  }

  $self->end_time = Time::HiRes::time;

  return 1;

}
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#
sub get_duration ()
{
  Trace(Caller(undef, @_));
  my $self = shift;
  return undef unless defined $self->{ &START_TIME }
                  and defined $self->{ &END_TIME   };
  return $self->{&END_TIME} - $self->{ &START_TIME };
}
#
#-------------------------------------------------------------------------------
#
sub get_end_time   () { Trace(Caller(undef, @_)); return $_[0]->{ &END_TIIME     } }
sub get_start_time () { Trace(Caller(undef, @_)); return $_[0]->{ &START_TIME    } }
sub get_stderr     () { Trace(Caller(undef, @_)); return $_[0]->{ &OUTPUT_STDERR } }
sub get_stdout     () { Trace(Caller(undef, @_)); return $_[0]->{ &OUTPUT_STDOUT } }
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

