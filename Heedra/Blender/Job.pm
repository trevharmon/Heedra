package Heedra::Blender::Job;

use strict;
use warnings;
use Config::IniFiles;
use Heedra::Blender::Constants qw( CYCLES PNG                        );
use Heedra::Blender::Utils     qw( :jobs :valid                      );
use Heedra::Log;
use Heedra::Utils              qw( array_contains is_valid_s3_bucket );


################################################################################
#
my ($_init);
$Carp::Internal{ (__PACKAGE__) }++;
#
################################################################################
#
use constant # Internal Data Structure
{
  CONFIG => 'config',
  JOB_ID => 'job_id',
  OWNER  => 'owner',
};
use constant # Job Configuration File
{
  BLEND       => 'blend',
  BUCKET      => 'bucket',
  END_FRAME   => 'end_frame',
  ENGINE      => 'engine',
  FORMAT      => 'format',
  INPUT       => 'input',
  JOB         => 'job',
  NAME        => 'name',
  OUTPUT      => 'output',
  RENDER      => 'render',
  SCENE       => 'scene',
  SCRIPT      => 'script',
  START_FRAME => 'start_frame',
  TEMPLATE    => 'template',
};
#
################################################################################
#
my %REQUIRED_MEMBERS;
   $REQUIRED_MEMBERS{ &INPUT  } = [ BLEND, BUCKET          ];
   $REQUIRED_MEMBERS{ &OUTPUT } = [ BUCKET, TEMPLATE       ];
   $REQUIRED_MEMBERS{ &RENDER } = [ END_FRAME, START_FRAME ];
my %OPTIONAL_MEMBERS;
   $OPTIONAL_MEMBERS{ &JOB    } = [ NAME                   ];
   $OPTIONAL_MEMBERS{ &OUTPUT } = [ FORMAT                 ];
   $OPTIONAL_MEMBERS{ &RENDER } = [ ENGINE, SCENE, SCRIPT  ];
my %MEMBER_DEFAULTS;
   $MEMBER_DEFAULTS{ &JOB    }{ &NAME   } = 'blender';
   $MEMBER_DEFAULTS{ &OUTPUT }{ &FORMAT } = PNG;
   $MEMBER_DEFAULTS{ &RENDER }{ &ENGINE } = CYCLES;
   $MEMBER_DEFAULTS{ &RENDER }{ &SCRIPT } = undef;
   $MEMBER_DEFAULTS{ &RENDER }{ &SCENE  } = undef;
#
################################################################################
#
my %MEMBER_VALIDATE;
   $MEMBER_VALIDATE{ &INPUT  }{ &BLEND       } = \&is_valid_blender_blend;
   $MEMBER_VALIDATE{ &INPUT  }{ &BUCKET      } = \&is_valid_s3_bucket;
   $MEMBER_VALIDATE{ &JOB    }{ &NAME        } = \&is_valid_blender_name;
   $MEMBER_VALIDATE{ &OUTPUT }{ &BUCKET      } = \&is_valid_s3_bucket;
   $MEMBER_VALIDATE{ &OUTPUT }{ &FORMAT      } = \&is_valid_blender_format;
   $MEMBER_VALIDATE{ &OUTPUT }{ &TEMPLATE    } = \&is_valid_blender_template;
   $MEMBER_VALIDATE{ &RENDER }{ &END_FRAME   } = \&is_valid_blender_frame;
   $MEMBER_VALIDATE{ &RENDER }{ &ENGINE      } = \&is_valid_blender_engine;
   $MEMBER_VALIDATE{ &RENDER }{ &SCENE       } = \&is_valid_blender_scene;
   $MEMBER_VALIDATE{ &RENDER }{ &SCRIPT      } = \&is_valid_blender_script;
   $MEMBER_VALIDATE{ &RENDER }{ &START_FRAME } = \&is_valid_blender_frame;

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
  my $self = shift;
  my $data = $_[0];

  # Load Data from Job Configuration File
  if (not defined $data)
  {
    Error('Missing job configuration file for new ' . __PACKAGE__);
    return undef;
  }
  my $ini = Config::IniFiles->new( -file => $data, -nocase => 1 );
  if (not defined $ini)
  {
    Error('Invalid job configuration file for new ' . __PACKAGE__);
    return undef;
  }

  # Set Data Structure Defaults
  foreach my $section (keys %REQUIRED_MEMBERS)
  {
    foreach my $member (@{$REQUIRED_MEMBERS{$section}})
    {
      $self->{&CONFIG}{$section}{$member} = undef;
    }
  }
  foreach my $section (keys %OPTIONAL_MEMBERS)
  {
    foreach my $member (@{$OPTIONAL_MEMBERS{$section}})
    {
      $self->{&CONFIG}{$section}{$member} = $MEMBER_DEFAULTS{$section}{$member};
    }
  }

  # Update Data from Job Configuratioan File
  foreach my $section ($ini->Sections)
  {
    foreach my $parameter ($ini->Parameters($section))
    {
      unless ( ( exists $REQUIRED_MEMBERS{$section}
                    and array_contains($REQUIRED_MEMBERS{$section}, $parameter)
               ) or (
                 exists $OPTIONAL_MEMBERS{$section}
                    and array_contains($OPTIONAL_MEMBERS{$section}, $parameter) ) )
      {
        Error("Unknown Entry in Job Configuration File [$section][$parameter]");
        next;
      }
      my $value = $ini->val($section, $parameter);
      if (defined $value)
      {
        if ('' eq $value)
        {
          $value = undef;
        }
        else
        {
          if (not &{$MEMBER_VALIDATE{$section}{$parameter}}($value))
          {
            Error("Invalid Value for [$section][$parameter] in Job Configuration File");
            return undef;
          }
        }
      }
      $self->{&CONFIG}{$section}{$parameter} = $value;
    }
  }

  # Set Job Meta-Data
  $self->{ &JOB_ID } = generate_job_id;
  $self->{ &OWNER  } = (getpwuid $>)[0];

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
my $_set = sub #($$$)#
{

  Trace(Caller('$_set', @_));
  my $self    = shift;
  my $section = $_[0];
  my $member  = $_[1];
  my $value   = $_[2];

  Fatal( 'Missing Section for _set' ) unless defined $section;
  Fatal( 'Missing Member for _set'  ) unless defined $member;

  return 0 unless defined $value
              and &{$MEMBER_VALIDATE{$section}{$member}}($value);
  $self->{&CONFIG}{$section}{$member} = $value;

  return 1;

};
#
#-------------------------------------------------------------------------------
#
sub frame_count ()
{
  Trace(Caller(undef, @_));
  my $self  = shift;
  my $start = $self->get_start_frame;
  my $end   = $self->get_end_frame;
  return (defined $start and defined $end) ? $end - $start : undef;
}
#
#-------------------------------------------------------------------------------
#
sub get_blend         () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &INPUT  }{ &BLEND       } }
sub get_end_frame     () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &RENDER }{ &END_FRAME   } }
sub get_engine        () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &RENDER }{ &ENGINE      } }
sub get_format        () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &OUTPUT }{ &FORMAT      } }
sub get_input_bucket  () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &INPUT  }{ &BUCKET      } }
sub get_job_id        () { Trace(Caller(undef, @_));
                           return $_[0]->{&JOB_ID}                            } 
sub get_job_name      () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &JOB    }{ &NAME        } }
sub get_output_bucket () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &OUTPUT }{ &BUCKET      } }
sub get_owner         () { Trace(Caller(undef, @_));
                           return $_[0]->{&OWNER}                             }
sub get_scene         () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &RENDER }{ &SCENE       } }
sub get_script        () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &RENDER }{ &SCRIPT      } }
sub get_start_frame   () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &RENDER }{ &START_FRAME } }
sub get_template      () { Trace(Caller(undef, @_));
                           return $_[0]->{&CONFIG}{ &OUTPUT }{ &TEMPLATE    } }
#
#-------------------------------------------------------------------------------
#
sub set_blend         { Trace(Caller(undef, @_));
                        return $_[0]->$_set( INPUT,  BLEND      , $_[1]) }
sub set_end_frame     { Trace(Caller(undef, @_));
                        return $_[0]->$_set( RENDER, END_FRAME  , $_[1]) }
sub set_engine        { Trace(Caller(undef, @_));
                        return $_[0]->$_set( RENDER, ENGINE     , $_[1]) }
sub set_format        { Trace(Caller(undef, @_));
                        return $_[0]->$_set( OUTPUT, FORMAT     , $_[1]) }
sub set_input_bucket  { Trace(Caller(undef, @_));
                        return $_[0]->$_set( INPUT,  BUCKET     , $_[1]) }
sub set_job_name      { Trace(Caller(undef, @_));
                        return $_[0]->$_set( JOB,    NAME       , $_[1]) }
sub set_output_bucket { Trace(Caller(undef, @_));
                        return $_[0]->$_set( OUTPUT, BUCKET     , $_[1]) }
sub set_scene         { Trace(Caller(undef, @_));
                        return $_[0]->$_set( RENDER, SCENE      , $_[1]) }
sub set_script        { Trace(Caller(undef, @_));
                        return $_[0]->$_set( RENDER, SCRIPT     , $_[1]) }
sub set_start_frame   { Trace(Caller(undef, @_));
                        return $_[0]->$_set( RENDER, START_FRAME, $_[1]) }
sub set_template      { Trace(Caller(undef, @_));
                        return $_[0]->$_set( OUTPUT, TEMPLATE   , $_[1]) }
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

