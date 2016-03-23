package Heedra::Blender::Utils;

use strict;
use warnings;
use Heedra::Blender::Constants qw( is_valid_engine is_valid_format );
use Heedra::Utils              qw( is_valid_filename               );
use Sys::Hostname;


################################################################################
#
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN
{
  require Exporter;
  @ISA = qw( Exporter );
  my @jobs     = qw( generate_job_id );
  my @valid    = qw( is_valid_blender_blend  is_valid_blender_engine
                     is_valid_blender_format is_valid_blender_frame
                     is_valid_blender_name   is_valid_blender_scene
                     is_valid_blender_script is_valid_blender_template );
  @EXPORT      = ( );
  @EXPORT_OK   = ( @jobs, @valid );
  %EXPORT_TAGS = ( all   => [ @EXPORT_OK ],
                   jobs  => [ @jobs      ],
                   valid => [ @valid     ],
                 );
}
#
################################################################################
#
my $Job_Counter = int(1000 * rand) % 1000;
#
################################################################################


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub generate_job_id ()
{
  my $host = hostname;
  $host =~ s/\..*$//;
  my @localtime = localtime(time);
  $Job_Counter  = ($Job_Counter + 1) % 1000;
  return sprintf '%s.%04d%02d%02d%02d%02d%02d.%05d%03d',
                 $host,
                 $localtime[5] + 1900,
                 $localtime[4],
                 $localtime[3],
                 $localtime[2],
                 $localtime[1],
                 $localtime[0],
                 $$,
                 $Job_Counter;
}
#TODO figure out why multiple jobs are getting the same job id
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_blender_blend #($)#
{
  my $data = $_[0];
  return ( not defined $data       ) ? 0 :
         ( $data =~ /^\S+\.blend$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_blender_engine #($)#
{
  my $data = $_[0];
  return 0 unless defined $data;
  return is_valid_engine($_[0]);
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_blender_format #($)#
{
  my $data = $_[0];
  return 0 unless defined $data;
  return is_valid_format($_[0]);
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_blender_frame #($)#
{
  my $data = $_[0];
  return ( not defined $data ) ? 0 :
         ( $data =~ /^\d+$/  ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_blender_name #($)#
{
  my $data = $_[0];
  return ( not defined $data      ) ? 0 :
         ( $data =~ /^[\w\.\-]+$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_blender_scene #($)#
{
  my $data = $_[0];
  return ( not defined $data   ) ? 0 :
         ( $data =~ /^[\S ]+$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_blender_script #($)#
{
  my $data = $_[0];
  return ( not defined $data    ) ? 0 :
         ( $data =~ /^\S+\.py$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_blender_template #($)#
{
  my $data = $_[0];
  return ( not defined $data ) ? 0 :
         ( $data !~ /#/      ) ? 0 :
         ( $data =~ /^\S+$/  ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


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

