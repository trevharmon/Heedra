package Heedra::Constants;

use strict;
use warnings;


################################################################################
#
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN
{
  require Exporter;
  my @environment   = qw( ENV_HEEDRA_HOME ENV_LOG_LEVEL      );
  my @configuration = qw( CONFIG_FILENAME CONFIG_SEARCH_PATH );

  @ISA         = qw( Exporter );
  @EXPORT      = qw( );
  @EXPORT_OK   =   ( @environment, @configuration );
  %EXPORT_TAGS = (
                   all    => [ @EXPORT_OK     ],
                   env    => [ @environment   ],
                   config => [ @configuration ],
                 );
}
#
################################################################################


################################################################################
#
use constant # Environment Variables
{
  ENV_HEEDRA_HOME => 'HEEDRA_HOME',
  ENV_LOG_LEVEL   => 'HEEDRA_LOG_LEVEL',
};
use constant # File Names
{
  CONFIG_FILENAME => 'heedra.conf',
};
#
################################################################################
#
my @CONFIGURATION_SEARCH_PATH = ( $ENV{&ENV_HEEDRA_HOME}, '/etc', './etc', '.' );
#
################################################################################


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub CONFIG_SEARCH_PATH ()
{
  return @CONFIGURATION_SEARCH_PATH;
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

