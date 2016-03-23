package Heedra::Log;

use strict;
use subs;
use warnings;
use Carp              qw( carp cluck croak );
use Config::IniFiles;
use DateTime;
use Heedra::Constants qw( :all );
use Heedra::Utils     qw( array_contains is_valid_filename );


################################################################################
#
our (@ISA, @EXPORT, @EXPORT_OK, %EXPORT_TAGS);
BEGIN
{
  require Exporter;
  @ISA          = qw( Exporter                                           );
  my @levels    = qw(                DEBUG ERROR FATAL   INFO TRACE WARN );
  my @loggers   = qw( Caller Confess Debug Error Fatal   Info Trace Warn );
  my @log_level = qw( get_log_level set_log_level is_valid_log_level     );
  my @verbose   = qw( get_verbose   set_verbose                          );
  @EXPORT       =   (  @levels, @loggers                                 );
  @EXPORT_OK    =   ( 'Initialize_Log', 'Log', @log_level, @verbose      );
  %EXPORT_TAGS  =   ( all       => [    @EXPORT, @EXPORT_OK ],
                      init      => [ qw(Initialize_Log)     ],
                      levels    => [    @levels             ],
                      loggers   => [    @loggers            ],
                      log_level => [    @log_level          ],
                      valid     => [ qw(is_valid_log_level) ],
                      verbose   => [    @verbose            ],
                    );
}
#
################################################################################


################################################################################
#
my  ($_log_level_to_str, $_log_level_to_int);
our $Initialized = 0;
$Carp::Internal{ (__PACKAGE__) }++;
#
################################################################################
#
use constant # Exported Log Levels
{
  TRACE => 5,
  DEBUG => 4,
  INFO  => 3,
  WARN  => 2,
  ERROR => 1,
  FATAL => 0,
};
my %LOG_LEVELS = ( 'TRACE' => TRACE,
                   'DEBUG' => DEBUG,
                   'INFO'  => INFO,
                   'WARN'  => WARN,
                   'ERROR' => ERROR,
                   'FATAL' => FATAL,
                 );
#
################################################################################
#
use constant # Configuration File Section
{
  ERROR_LOG => 'error_log',
  LOG       => 'log',
  LOG_LEVEL => 'log_level',
};
#
################################################################################
#
my  $Log_Level  = INFO;
my  $Log_StdErr = undef;
my  $Log_StdOut = undef;
our $Verbose   = 0;
#
################################################################################


#===============================================================================
#
sub Initialize_Log #($)#
{

  my $conf = $_[0];
  if (not defined $conf)
  {
    carp 'Missing configuration for Initialize_Log';
    return 0;
  }
  if ('Config::IniFiles' ne ref $conf)
  {
    carp 'Invalid configuration for Initialize_Log';
    return 0;
  }

  # Load Data
  my $error_log = $conf->val( LOG, ERROR_LOG );
  my $log       = $conf->val( LOG, LOG       );
  my $log_level = $conf->val( LOG, LOG_LEVEL );
  set_log_level($log_level) if defined $log_level;

  # Set up Log Files per Config File
  if (defined $log)
  {
    if (not is_valid_filename($log))
    {
      carp "Invalid filename for Log: $log";
      return 0;
    }
    if (not open LOG_OUT, ">>$log")
    {
      carp "Cannot open log file '$log' for write: $!";
      return 0;
    }
    $Log_StdOut = *LOG_OUT;
  }
  if (defined $error_log and length $error_log)
  {
    if (not is_valid_filename($error_log))
    {
      carp "Invalid filename for Error Log: $error_log";
      return 0;
    }
    if (not open LOG_ERR, ">>$error_log")
    {
      carp "Cannot open error log file '$error_log' for write: $!";
      return 0;
    }
    $Log_StdErr = *LOG_ERR;
  }

  $Initialized = 1;

  return 1;

}
#
#===============================================================================


#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub Log
{

  my $level   = $_[0];
  my $message = $_[1];
  my $result  = 1;

  # 'Fix' Input Parameters
  $message = '<UNKNOWN>' unless defined $message;
  if (not defined $level or not &is_valid_log_level($level))
  {
    $level   = FATAL;
    $message = "$message<BAD LOG LEVEL>";
  }
  else
  {
    $level = &$_log_level_to_int($level);
  }

  if ($level <= $Log_Level)
  {

    # Build Message
    # [timestamp] [pid] [datetime] [level]\tmessage
    my $now   =  time;
    my $dt    =  DateTime->from_epoch( epoch => $now );
    $message  =~ s/\s+$/\n/s;      # Remove trailing space
    $message  =~ s/[\r\n]+/\n\t/g; # Tab-indent subsequent lines
    my $entry =  sprintf "[%d] [%05d] [%02d %s %4d %s] [%s]\t%s\n",
                         $now,
                         $$,
                         $dt->day, $dt->month_abbr, $dt->year,
                         $dt->hms,
                         &$_log_level_to_str($level),
                         $message;

    if ($Initialized)
    {
      # Write to Terminal
      print $entry if $Verbose and $level > WARN;

      # Write to Log Files
      $result = 0 unless print $Log_StdOut $entry;
      warn "$!\nENTRY: $entry" unless $result;
      if ($level <= WARN and defined $Log_StdErr)
      {
        $result = 0 unless print $Log_StdErr $entry;
        warn "$!\nENTRY: $entry" unless $result;
      }
    }

    # Handle Errors
    print STDERR $entry if $level <= WARN or ( not $Initialized
                                               and $Verbose     );
    carp  $message      if $level == ERROR;
    croak $message      if $level == FATAL;

  }

  return $result;

}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub Trace { return Log( TRACE, $_[0] ) }
sub Debug { return Log( DEBUG, $_[0] ) }
sub Error { return Log( ERROR, $_[0] ) }
sub Fatal {        Log( FATAL, $_[0] ) } # Does not return
sub Info  { return Log( INFO,  $_[0] ) }
sub Warn  { return Log( WARN,  $_[0] ) }
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub Confess #(;$)#
{
  Fatal cluck($_[0]); # Does not return
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub Caller #($@)#
{

  my ($function, @parameters) = @_;
  $function = (defined $function) ? $function : '';
  $function = (caller(1))[3] . $function;
  $function =~ s/__ANON__//;
  my $params   = '';

  foreach my $param (@parameters)
  {
    $param   = '<undef>' unless defined $param;
    $params .= (length ref $param)
             ? $param . ', '
             : "'$param', ";
  }
  $params =~ s/,\s$//;

  return "$function($params)";

}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub is_valid_log_level #($)#
{
  my $level = $_[0];
  my @vals  = values %LOG_LEVELS;
  return ( not defined $level             ) ? 0 :
         ( exists $LOG_LEVELS{$level}     ) ? 1 :
         ( array_contains(\@vals, $level) ) ? 1 : 0;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub get_log_level () { return $Log_Level }
sub get_verbose   () { return $Verbose   }
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub set_log_level #($)#
{
  Trace(Caller(undef, @_));
  my $level = $_[0];
  if (not is_valid_log_level($level))
  {
    warn ("Invalid Log Level for set_log_level: $level");
    return 0;
  }
  $Log_Level = &$_log_level_to_int($level);
  return 1;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
sub set_verbose #($)#
{
  Trace(Caller(undef, @_));
  $Verbose = $_[0] ? 1 : 0;
  return 1;
}
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
$_log_level_to_int = sub #($)#
{
  my $level = $_[0];

  return undef unless defined $level;
  return $LOG_LEVELS{$level} if exists $LOG_LEVELS{$level};
  return undef unless $level =~ /^\d+$/;

  foreach my $key (keys %LOG_LEVELS)
  {
    return $LOG_LEVELS{$key} if $level == $LOG_LEVELS{$key};
  }

  return undef;

};
#
#+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
#
$_log_level_to_str = sub #($)#
{

  my $level = $_[0];

  return undef  unless defined $level;
  return $level if exists $LOG_LEVELS{$level};
  return undef  unless $level =~ /^\d+$/;

  foreach my $key (keys %LOG_LEVELS)
  {
    return $key if $level == $LOG_LEVELS{$key};
  }

  return undef;

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

