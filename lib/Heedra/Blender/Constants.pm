package Heedra::Blender::Constants;

use strict;
use warnings;
use Heedra::Log;
use Heedra::Utils qw( array_contains );
require Exporter;


################################################################################
#
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
our (@ENGINES, @FORMATS, @FORMATS_DEFAULTS, @FORMATS_OPTIONAL);
BEGIN
{
  require Exporter;
  @ISA          = qw( Exporter );

  @ENGINES          = qw( BLENDER  CYCLES                            );
  @FORMATS_DEFAULTS = qw( AVIJPEG  AVIRAW    BMP  FRAMESERVER  FTYPE
                          HAMX     IRIS      IRIZ JPEG         MOVIE
                          PNG      RAWTGA    TGA                     );
  @FORMATS_OPTIONAL = qw( AVICODEC CINEON    DPX  EXR          HDR
                          MPEG     QUICKTIME TIFF                    );
  @FORMATS          = sort ( @FORMATS_DEFAULTS, @FORMATS_OPTIONAL );

  my @get_valid = qw( get_valid_engines
                      get_valid_formats
                      get_valid_default_formats
                      get_valid_optional_formats );
  my @is_valid  = qw( is_valid_engine
                      is_valid_format
                      is_valid_default_format
                      is_valid_optional_format );

  @EXPORT       = ( );
  @EXPORT_OK    = ( @ENGINES, @FORMATS, @get_valid, @is_valid );
  %EXPORT_TAGS  = ( all    => [ @EXPORT_OK ],
                    engine => [ @ENGINES,
                                qw( get_valid_engines
                                    is_valid_engine   ) ],
                    format => [ @FORMATS,
                                qw( get_valid_formats
                                    is_valid_format   ) ],
                    valid  => [ @get_valid, @is_valid   ],
                  );
}
#
################################################################################


################################################################################
#
use constant # Engines
{
  BLENDER => 'BLENDER',
  CYCLES  => 'CYCLES',
};
use constant # Formats
{
  AVICODEC    => 'AVICODEC',
  AVIJPEG     => 'AVIJPEG',
  AVIRAW      => 'AVIRAW',
  BMP         => 'BMP',
  CINEON      => 'CINEON',
  DPX         => 'DPX',
  EXR         => 'EXR',
  FRAMESERVER => 'FRAMESERVER',
  FTYPE       => 'FTYPE',
  HAMX        => 'HAMX',
  HDR         => 'HDR',
  IRIS        => 'IRIS',
  IRIZ        => 'IRIZ',
  JPEG        => 'JPEG',
  MOVIE       => 'MOVIE',
  MPEG        => 'MPEG',
  PNG         => 'PNG',
  QUICKTIME   => 'QUICKTIME',
  RAWTGA      => 'RAWTGA',
  TGA         => 'TGA',
  TIFF        => 'TIFF',
};
#
################################################################################


#-------------------------------------------------------------------------------
#
sub get_valid_engines          () { Trace(Caller(undef, @_));
                                    return @ENGINES;          }
sub get_valid_formats          () { Trace(Caller(undef, @_));
                                    return @FORMATS;          }
sub get_valid_default_formats  () { Trace(Caller(undef, @_));
                                    return @FORMATS_DEFAULTS; }
sub get_valid_optional_formats () { Trace(Caller(undef, @_));
                                    return @FORMATS_OPTIONAL; }
#
#-------------------------------------------------------------------------------


#-------------------------------------------------------------------------------
#
my $_valid = sub #(\$$)#
{

  Trace(Caller('$_valid', @_));
  my $dataset = $_[0];
  my $value   = $_[1];

  return 0 unless defined $dataset
              and defined $value
              and 'ARRAY' eq ref $dataset;

  return array_contains($dataset, $value);

};
#-------------------------------------------------------------------------------
sub is_valid_engine          { Trace(Caller(undef, @_));
                               return &$_valid( \@ENGINES,          $_[0] ) }
sub is_valid_format          { Trace(Caller(undef, @_));
                               return &$_valid( \@FORMATS,          $_[0] ) }
sub is_valid_default_format  { Trace(Caller(undef, @_));
                               return &$_valid( \@FORMATS_DEFAULTS, $_[0] ) }
sub is_valid_optional_format { Trace(Caller(undef, @_));
                               return &$_valid( \@FORMATS_OPTIONAL, $_[0] ) }
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

