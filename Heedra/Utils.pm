package Heedra::Utils;

use strict;
use warnings;
use Carp;


################################################################################
#
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN
{
  require Exporter;
  @ISA         = qw( Exporter );
  my @array    = qw( array_contains );
  my @valid    = qw( is_valid_access_key
                     is_valid_filename
                     is_valid_host
                     is_valid_ip
                     is_valid_md5
                     is_valid_message_id
                     is_valid_package
                     is_valid_password
                     is_valid_port
                     is_valid_receipt_handle
                     is_valid_s3_bucket
                     is_valid_secret_key
                     is_valid_sqs_queue
                     is_valid_timestamp
                     is_valid_type
                     is_valid_username
                     is_valid_version    );
  @EXPORT      = qw( );
  @EXPORT_OK   = ( @array, @valid );
  %EXPORT_TAGS = (
                   all   => [ @EXPORT_OK ],
                   array => [ @array     ],
                   valid => [ @valid     ],
                 );
}
#
################################################################################


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_access_key #($)#
{
  my $data = $_[0];
  return ( not defined $data   ) ? 0 :
         ( $data =~ /^\S{20}$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_filename #($)#
{
  my $data = $_[0];
  return ( not defined $data ) ? 0 :
         ( $data =~ /^\/\p{IsPrint}+$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_host #($)#
{
  my $data = $_[0];
  return ( not defined $data      ) ? 0 :
         ( $data =~ /^[\w\-\.]+$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_ip #($)#
{
  my $data = $_[0];
  return 0 unless defined $data;
  return 0 unless $data =~ /^(\d+)\.(\d+)\.(\d+)\.(\d+)$/;
  return ( $1 < 256 and $2 < 256 and $3 < 256 and $4 < 256 ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_md5 #($)#
{
  my $data = $_[0];
  return ( not defined $data ) ? 0 :
         ( $data =~ /^[a-f\d]{32}$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_message_id #($)#
{
  my $data = $_[0];
  return ( not defined $data          ) ? 0 :
         ( $data =~ /^[a-f\d\-]{36}$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_package #($)#
{
  my $data = $_[0];
  return (not defined $data     ) ? 0 :
         ( $data =~ /[^:]:[^:]/ ) ? 0 :
         ( $data =~ /^:|:$/     ) ? 0 :
         ( $data =~ /^[\w:]+$/  ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_password #($)#
{
  my $data = $_[0];
  return ( not defined $data ) ? 0 :
         ( $data =~ /^\S+$/  ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_port #($)#
{
  my $data = $_[0];
  return ( not defined $data ) ? 0 :
         ( $data !~ /^\d+$/  ) ? 0 :
         ( $data < 0         ) ? 0 :
         ( $data > 65535     ) ? 0 : 1;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_receipt_handle #($)#
{
  my $data = $_[0];
  return ( not defined $data ) ? 0 :
         ( $data =~ /^\S+$/  ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_s3_bucket #($)#
{
  my $data = $_[0];
  return ( not defined $data           ) ? 0 :
         ( $data =~ /^s3:\/\/[\w\-]+$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_secret_key #($)#
{
  my $data = $_[0];
  return ( not defined $data   ) ? 0 :
         ( $data =~ /^\S{40}$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_sqs_queue #($)#
{
  my $data = $_[0];
  return ( not defined $data      ) ? 0 :
         ( $data =~ /^[\w\-\.]+$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_timestamp #($)#
{
  my $data = $_[0];
  return ( not defined $data   ) ? 0 :
         ( $data =~ /^\d{10}$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_type #($)#
{
  my $data = $_[0];
  return ( not defined $data   ) ? 0 :
         ( $data =~ /^[\w:]+$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_username #($)#
{
  my $data = $_[0];
  return ( not defined $data ) ? 0 :
         ( $data =~ /^\w+$/  ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_version #($)#
{
  my $data = $_[0];
  return ( not defined $data            ) ? 0 :
         ( $data =~ /^\d{4}-\d\d-\d\d$/ ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub array_contains #(\$$)#
{

  my $ref   = $_[0];
  my $value = $_[1];

  confess 'Missing array reference for _contains' unless defined $ref;
  confess 'Invalid array reference for _contains' unless 'ARRAY' eq ref $ref;

  my $found = 0;
  foreach my $entry (@{$ref})
  {
    if (not defined $value or not defined $entry)
    {
      $found = 1 if not defined $value and not defined $entry;
    }
    else
    {
      $found = 1 if $entry eq $value;
    }
    last if $found;
  }

  return $found;

};
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

