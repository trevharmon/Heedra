package Heedra::Blender::Handler;

use strict;
use warnings;
use Heedra::Blender::Payload qw( :all               );
use Heedra::Blender::Utils   qw( :valid             );
use Heedra::Log;
use Heedra::Utils            qw( is_valid_s3_bucket );
use IPC::Run                 qw( run                );
use Time::HiRes              qw( ); # Don't Import Anything


################################################################################
#
my ($_init, $_run);
$Carp::Internal{ (__PACKAGE__)}++;
#
################################################################################
#
use constant
{
  BLENDER       => 'blender',
  END_TIME      => 'end_time',
  OUTPUT_STDERR => 'stderr',
  OUTPUT_STDOUT => 'stdout',
  PAYLOAD       => 'payload',
  SCRATCH       => 'scratchi_dir',
  S3CMD         => 's3cmd',
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
  my $package = __PACKAGE__;

  if (not defined $payload)
  {
    Error("Missing Payload for $package (handler)");
    return undef;
  }
  if ('Heedra::Blender::Payload' ne ref $payload)
  {
    Error("Invalid Payload for $package (handler): " . ref($payload));
    return undef;
  }

  # Re-verify All Payload Members (paranoid)
  if (not is_valid_blender_frame($payload->get_end_frame))
  {
    Error("Invalid Payload End Frame for $package (handler)");
    return undef;
  }
  if (not is_valid_blender_frame($payload->get_start_frame))
  {
    Error("Invalid Payload Start Frame for $package (handler)");
    return undef;
  }
  if ('Heedra::Blender::Job' ne ref $payload->job)
  {
    Error("Invalid Job Definition for $package (handler)");
    return undef;
  }

  # Re-verify All Jobs Members (paranoid)
  if (not is_valid_blender_blend($payload->job->get_blend))
  {
    Error("Invalid .blend File for $package (handler)");
    return undef;
  }
  if (not is_valid_blender_frame($payload->job->get_end_frame))
  {
    Error("Invalid Job End Frame for $package (handler)");
    return undef;
  }
  if (not is_valid_blender_engine($payload->job->get_engine))
  {
    Error("Invalid Engine for $package (handler)");
    return undef;
  }
  if (not is_valid_blender_format($payload->job->get_format))
  {
    Error("Invalid Output Format for $package (handler)");
    return undef;
  }
  if (not is_valid_s3_bucket($payload->job->get_input_bucket))
  {
    Error("Invalid Input S3 Bucket for $package (handler)");
    return undef;
  }
  if (not is_valid_blender_name($payload->job->get_job_name))
  {
    Error("Invalid Job Name for $package (handler)");
    return undef;
  }
  if (not is_valid_s3_bucket($payload->job->get_output_bucket))
  {
    Error("Invalid Output S3 Bucket for $package (handler)");
    return undef;
  }
  if ( defined $payload->job->get_scene
       and not is_valid_blender_scene($payload->job->get_scene) )
  {
    Error("Invalid Scene for $package (handler)");
    return undef;
  }
  if ( defined $payload->job->get_script
       and not is_valid_blender_script($payload->job->get_script) )
  {
    Error("Invalid Pre-Process Script for $package (handler)");
    return undef;
  }
  if (not is_valid_blender_frame($payload->job->get_start_frame))
  {
    Error("Invalid Job Start Frame for $package (handler)");
    return undef;
  }
  if (not is_valid_blender_template($payload->job->get_template))
  {
    Error("Invalid Output Template for $package (handler)");
    return undef;
  }

  # Sanity Check Requested Frames
  my $job_start = $payload->job->get_start_frame;
  my $job_end   = $payload->job->get_end_frame;
  my $pay_start = $payload->get_start_frame;
  my $pay_end   = $payload->get_end_frame;
  if ($job_start > $job_end)
  {
    Error("Job Start Frame ($job_start) Is After Job End Frame ($job_end) - Fixing");
    return undef;
  }
  if ($pay_start > $pay_end)
  {
    Error("Requested Start Frame ($pay_start) Is After Requested End Frame ($pay_end)");
    return undef;
  }
  unless ( $pay_start >= $job_start and $pay_end >= $job_start and
           $pay_start <= $job_end   and $pay_end <= $job_end     )
  {
    Error("Requested Frames ($pay_start-$pay_end) Not Part of Job ($job_start-$job_end)");
    return undef;
  }

  # Set Executables & Directories
  $self->{ &BLENDER } = 'blender';
  $self->{ &S3CMD   } = 's3cmd';
  $self->{ &SCRATCH } = '/tmp/';
  if (exists $config->{&BLENDER})
  {
    if ( defined $config->{&BLENDER} and -x $config->{&BLENDER} )
    {
      $self->{&BLENDER} = $config->{&BLENDER};
    }
    else
    {
      Error('Invalid Blender Executable: ' . $config->{&BLENDER});
      return undef;
    }
  }
  if (exists $config->{&S3CMD})
  {
    if ( defined $config->{&S3CMD} and -x $config->{&S3CMD} )
    {
      $self->{&S3CMD} = $config->{&S3CMD};
    }
    else
    {
      Error('Invalid S3Cmd Executable: ' . $config->{&S3CMD});
      return undef;
    }
  }
  if (exists $config->{&SCRATCH})
  {
    if ( defined $config->{&SCRATCH} and -d $config->{&SCRATCH}
          and -r $config->{&SCRATCH} and -w $config->{&SCRATCH} )
    {
      $self->{&SCRATCH} = $config->{&SCRATCH};
    }
    else
    {
      Error('Invalid Scatch/Work Directory: ' . $config->{&SCRATCH});
      return undef;
    }
  }

  # Clean-up
  $self->{ &OUTPUT_STDERR } = undef;
  $self->{ &OUTPUT_STDOUT } = undef;
  $self->{ &PAYLOAD       } = $payload;
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
$_run = sub #(@)#
{

  Trace(Caller('$_run', @_));
  my $self = shift;
  my ($in, $out, $err, $sys);
  my @cmd  = @_;

  Debug('CMD: ' . join(' ', @cmd));
  run \@cmd, \$in, \$out, \$err;
  $sys = $?;
  $out = '' unless defined $out;
  $err = '' unless defined $err;

  $self->{&OUTPUT_STDOUT}  = $out;
  $self->{&OUTPUT_STDERR}  = $err;
  if ($sys)
  {
    # Something went wrong
    $self->{&OUTPUT_STDERR} .= "\n$sys";
    return 0;
  }

  return 1;

};
#
#-------------------------------------------------------------------------------
#
sub execute ()
{

  Trace(Caller(undef, @_));
  my $self    = shift;
  my $payload = $self->{&PAYLOAD};
  my $job     = $payload->job;
  my $job_id  = $job->get_job_id;

  $self->{&START_TIME} = Time::HiRes::time;
  Info  ( "Starting Blender Job '$job_id'");
  Debug ( 'Render started at: ' . $self->{&START_TIME});

  # Work out directories, filenames and URLs
  Debug('Determining directories, filenames and URLs');
  my $local_dir    = $self->{&SCRATCH};
  my $local_blend  =  $local_dir . '/' . $job->get_blend;
     $local_blend  =~ s|//|/|g;
  my $remote_blend =  $job->get_input_bucket . '/' . $job->get_blend;
     $remote_blend =~ s|(?<!s3:)//|/|g;
  my $local_frame  =  $local_dir . '/' . $job->get_template;
     $local_frame  =~ s|//|/|g;
  Debug("Remote Blend: $remote_blend");
  Debug("Local Blend: $local_blend");
  Debug("Work Directory: $local_dir");
  Debug("Ouput Template: $local_frame");

  # Verify Output Directory/Template
  if (not -d $local_dir)
  {
    $self->{&OUTPUT_STDERR} = "Invalid Work Directory (not a directory): $local_dir";
    Error($self->{&OUTPUT_STDERR});
    return 0;
  }
  if (not -r $local_dir)
  {
    $self->{&OUTPUT_STDERR} = "Invalid Work Directory (not readable): $local_dir";
    Error($self->{&OUTPUT_STDERR});
    return 0;
  }
  if (not -w $local_dir)
  {
    $self->{&OUTPUT_STDERR} = "Invalid Work Directory (not writeable): $local_dir";
    Error($self->{&OUTPUT_STDERR});
    return 0;
  }
#TODO test a bad output template (i.e., not enought #'s)

  # Verify executables
  if (not -x $self->{&BLENDER})
  {
    $self->{&OUTPUT_STDERR} = 'Invalid Blender Executable (not executable): ' . $self->{&BLENDER};
    Error($self->{&OUTPUT_STDERR});
    return 0;
  }
  if (not -x $self->{&S3CMD})
  {
    $self->{&OUTPUT_STDERR} = 'Invalid S3Cmd Executable (not executable): ' . $self->{&S3CMD};
    Error($self->{&OUTPUT_STDERR});
    return 0;
  }

  # Verify/Retrieve Input Source Files
  Info("Looking for blend file");
  if (not -B $local_blend)
  {
    Info("Blend file needs to be downloaded from $remote_blend");
    return 0 unless $self->$_run($self->{&S3CMD}, 'get', $remote_blend, $local_blend);
#TODO check output to see if command was successful
    Info('Blend file download complete');
  }
  else
  {
    Info("Blend file is already located at $local_blend");
  }
  if (not -r $local_blend)
  {
    $self->{&OUTPUT_STDERR} = "Invalid Blend (not readable): $local_blend";
    Error($self->{&OUTPUT_STDERR});
    return 0;
  }
  if (not -B $local_blend)
  {
    $self->{&OUTPUT_STDERR} = "Invalid Blend (not binary file): $local_blend";
    Error($self->{&OUTPUT_STDERR});
    return 0;
  }

  # Run Render Job
  Debug('Preparing to render blend file');
  RENDER:
  { 

    my $start_frame = $payload->get_start_frame;
    my $end_frame   = $payload->get_end_frame;
    my $frame_stub  = ($start_frame == $end_frame)
                    ? " #$start_frame"
                    : "s #$start_frame-$end_frame";

    # !! Order Matters for Blender Commandline Arguments !!
    my @cmd = ( $self->{&BLENDER},
                '-b', $local_blend,
                '-o', $local_frame,
                '--engine', $job->get_engine,
                '-F', $job->get_format,
                '-x', 1,
                '-noaudio'
              );
    push @cmd, '-S', $job->get_scene  if defined $job->get_scene;
    push @cmd, '-P', $job->get_script if defined $job->get_script;
    if ($start_frame == $end_frame)
    {
      push @cmd, '-f', $start_frame;
    }
    else
    {
      push @cmd, '-s', $start_frame,
                 '-e', $end_frame,
                 '-a';
    }
    Debug ( 'Prepared Command: ' . join(' ', @cmd) );
    Info  ( "Rendering Frame$frame_stub"           );

    return 0 unless $self->$_run(@cmd);
    Info("Frame$frame_stub Complete");

    # Stage Out Completed File(s)
    Debug( sprintf 'Preparing to stage rendered%s frame to S3',
                   ($start_frame == $end_frame) ? '' : 's'      );
    my $stdout_text   = $self->{&OUTPUT_STDOUT};
    my $stderr_text   = $self->{&OUTPUT_STDERR};
    my $output_bucket = $job->get_output_bucket;
    my $frame_count   = 0;
    while ($stdout_text =~ /Saved:\s(.+?)[\r\n]/gs)
    {
      my $completed_frame = $1;
      Info("Uploading completed frame '$completed_frame' to $output_bucket");
      return 0 unless $self->$_run($self->{&S3CMD}, 'put', $completed_frame, $output_bucket);
#TODO check output to see if command was successful
      Info("Deleting $completed_frame");
      unlink $completed_frame;
      $frame_count++;
    }
    if ($frame_count != $start_frame - $end_frame + 1)
    {
      Error( sprintf 'Could not determine%s filename%s for completed frame%s: %d found',
                     ($start_frame == $end_frame) ? '' : ' all',
                     ($start_frame == $end_frame) ? '' : 's',
                     $frame_stub,
                     $frame_count
           );
      return 0;
    }

  }
  Info("Finished Blender Job '$job_id'");

  $self->{&END_TIME} = Time::HiRes::time;
  Debug('Render completed at: ' . $self->{&END_TIME});

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

