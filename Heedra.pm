package Heedra;

use strict;
use warnings;
use Config::IniFiles;
use Heedra::Constants qw( :all                  );
use Heedra::Log       qw( :DEFAULT :init :valid );
use Heedra::Queue;
use Heedra::Utils     qw( :array :valid         );


################################################################################
#
my ($_init, $_set, $_reset_queue ); 
#
################################################################################
#
use constant # Internal
{
  SQS_QUEUE => 'SQS_Queue',
};
use constant # Sections
{
  AWS      => 'aws',
  DATABASE => 'database',
  HANDLER   => 'handler',
  LOG      => 'log',
};
use constant # Members
{
  ACCESS_KEY  => 'access_key',
  ERROR_LOG   => 'error_log',
  HOST        => 'host',
 #LOG         => 'log', # Defined in Sections
  LOG_LEVEL   => 'log_level',
  PASSWORD    => 'password',
  PORT        => 'port',
  QUEUE       => 'queue',
  SECRET_KEY  => 'secret_key',
  USERNAME    => 'username',
};
#
################################################################################
#
my  %DATA_SECTIONS;
    $DATA_SECTIONS{ &AWS        } = [ ACCESS_KEY, SECRET_KEY, QUEUE  ];
    $DATA_SECTIONS{ &DATABASE   } = [ HOST, PORT, USERNAME, PASSWORD ];
    $DATA_SECTIONS{ &HANDLER    } = [ ]; # Special Processing
    $DATA_SECTIONS{ &LOG        } = [ LOG, LOG_LEVEL, ERROR_LOG      ];
my  %DATA_VALIDATE;
    $DATA_VALIDATE{ &ACCESS_KEY } = \&is_valid_access_key;
    $DATA_VALIDATE{ &ERROR_LOG  } = \&is_valid_filename;
    $DATA_VALIDATE{ &HOST       } = \&is_valid_host;
    $DATA_VALIDATE{ &LOG        } = \&is_valid_filename;
    $DATA_VALIDATE{ &LOG_LEVEL  } = \&is_valid_log_level;
    $DATA_VALIDATE{ &PASSWORD   } = \&is_valid_password;
    $DATA_VALIDATE{ &PORT       } = \&is_valid_port;
    $DATA_VALIDATE{ &QUEUE      } = \&is_valid_sqs_queue;
    $DATA_VALIDATE{ &SECRET_KEY } = \&is_valid_secret_key;
    $DATA_VALIDATE{ &USERNAME   } = \&is_valid_username;
#
################################################################################


#===============================================================================
#
sub new #(%)#
{
  Trace(Caller('$_reset_queue', @_));
  my $class = shift;
  my $self  = {};
  bless $self, $class;
  return $self->$_init(@_);

}
#
#===============================================================================
#
$_init = sub #(%)#
{

  Trace(Caller('$_reset_queue', @_));
  my $self        = shift;
  my %data        = @_;
  my $conf        = undef;
  my $config_file = undef;
  my %load_data   = ();

  Info('Initializing ' . __PACKAGE__ . ' System');

  # Reset Data Structures
  foreach my $section (keys %DATA_SECTIONS)
  {
    $self->{$section} = {};
    foreach my $member (@{$DATA_SECTIONS{$section}})
    {
      $self->{$section}{$member} = undef;
    }
  }
  $self->{&SQS_QUEUE} = undef;

  # Load Config File
  {
    foreach my $dir (CONFIG_SEARCH_PATH)
    {
      # Find Config File
      $config_file = "$dir/" . CONFIG_FILENAME;
      $config_file =~ s|//|/|g;
      $conf = Config::IniFiles->new( -file => $config_file )
        if -T $config_file;
      last if defined $conf;
    }
    if (not defined $conf)
    {
      my $message = "Cannot find config file '" . CONFIG_FILENAME . "'. "
                  . ' Search path: ';
      foreach my $dir (CONFIG_SEARCH_PATH)
      {
        my $name =  "'$dir/', ";
           $name =~ s|//|/|g;
        $message .= $name;
      }
      $message =~ s/[\s,]+$//;
      Error($message);
      return undef;
    }
    Info("Configuration File: $config_file");

    # Load Information from Config File
    foreach my $section (keys %DATA_SECTIONS)
    {
      foreach my $parameter (@{$DATA_SECTIONS{$section}})
      {
        $load_data{$section}{$parameter} = $conf->val($section, $parameter);
      }
    }
  }

  # Override with Provided Values
  foreach my $section (keys %data)
  {
    foreach my $parameter (keys %{$data{$section}})
    {
      next unless array_contains($DATA_SECTIONS{$section}, $parameter);
      $load_data{$section}{$parameter} = $data{$parameter};
    }
  }

  # Set Log Level
  Heedra::Log::set_log_level($load_data{&LOG}{&LOG_LEVEL});

  # Set Object Values
  foreach my $section (keys %load_data)
  {
    foreach my $parameter (keys %{$load_data{$section}})
    {
      $self->$_set( $section,
                    $parameter,
                    $load_data{$section}{$parameter},
                    $DATA_VALIDATE{$parameter});
    }
  }

  # Have to wait until here to do the processing
  Fatal("Cannot Start Logging Engine") unless Initialize_Log($conf);
  # Can now use extended logging mechanisms

  # Handlers
  my $handler_count = 0;
  foreach my $payload ($conf->Parameters(HANDLER))
  {

    # Discover Handlers
    if (not is_valid_package($payload))
    {
      Error( "Invalid Handler Package: $payload" );
      return undef;
    }
    my $handler = $conf->val(HANDLER, $payload);
    if (not defined $handler)
    {
      Error( "Missing $payload Handler" );
      return undef;
    }
    if (not is_valid_package($handler))
    {
      Error( "Invalid $payload Handler: $handler" );
      return undef;
    }

    # Load Handlers
    eval "require $payload;";
    Fatal("Failed to Load $payload Package: $@") if $@;
    eval "require $handler;";
    Fatal("Failed to Load $payload Handler: $handler: $@") if $@;
    $self->{&HANDLER}{$payload}{&HANDLER} = $handler;

    # Load Handler Configurations from Configuration File
    foreach my $entry ($conf->Parameters($payload))
    {
      $self->{&HANDLER}{$payload}{$entry} = $conf->val($payload, $entry);
    }

    Info("Registered $payload Handler: $handler");
    $handler_count++;

  }
  if (not $handler_count)
  {
    Error("No Handlers Initialized in Configuration File");
    return $self;
  }

  return $self;

};
#
#===============================================================================
#
$_reset_queue = sub #()#
{

  Trace(Caller('$_reset_queue', @_));
  my $self       = shift;
  my $access_key = $self->get_access_key;
  my $secret_key = $self->get_secret_key;
  my $queue      = $self->get_queue_name;

  Confess('Missing Access Key for _reset_queue' ) unless defined $access_key;
  Confess('Missing Secret Key for _reset_queue' ) unless defined $secret_key;
  Confess('Missing SQS Queue for _reset_queue'  ) unless defined $queue;

  $self->{&SQS_QUEUE} = Heedra::Queue->new( access_key => $access_key,
                                            secret_key => $secret_key,
                                            name       => $queue       );

  return;

};
#
#===============================================================================
#
sub DESTROY {}
#
#===============================================================================


#-------------------------------------------------------------------------------
#
sub publish #($)#
{
  Trace(Caller(undef, @_));
  my $self = shift;
  Fatal   ( 'Missing SQS Queue' ) unless defined $self->{&SQS_QUEUE};
  Confess ( 'Invalid SQS Queue' ) unless 'Heedra::Queue' eq ref $self->{&SQS_QUEUE};
  return $self->queue->publish(@_);
}
#
#-------------------------------------------------------------------------------
#
sub consume ()
{
  Trace(Caller(undef, @_));
  my $self = shift;
  Fatal   ( 'Missing SQS Queue' ) unless defined $self->{&SQS_QUEUE};
  Confess ( 'Invalid SQS Queue' ) unless 'Heedra::Queue' eq ref $self->{&SQS_QUEUE};
  return $self->queue->consume(@_);
}
#
#-------------------------------------------------------------------------------
#
sub delete_message #($)#
{
  Trace(Caller(undef, @_));
  my $self = shift;
  Fatal   ( 'Missing SQS Queue' ) unless defined $self->{&SQS_QUEUE};
  Confess ( 'Invalid SQS Queue' ) unless 'Heedra::Queue' eq ref $self->{&SQS_QUEUE};
  return $self->queue->delete_message(@_);
}
#
#-------------------------------------------------------------------------------
#
sub execute #($)#
{

  Trace(Caller(undef, @_));
  my $self    = shift;
  my $message = $_[0];

  # Sanity Check
  if (not defined $message)
  {
    Error('Missing Message for execute');
    return 0;
  }
  if (not ref $message or not $message->isa('Heedra::Message'))
  {
    Error('Invalid Message for execute');
    return 0;
  }

  # Look for Handler
  my $payload = $message->payload;
  if (not defined $payload)
  {
    Error('Missing Payload for execute');
    return 0;
  }
  my $type = ref $payload;

  if (not exists $self->{&HANDLER}{$type}{&HANDLER})
  {
    Error("Handler for $type either not installed or not configured");
    return 0;
  }
  my $package = $self->{&HANDLER}{$type}{&HANDLER};
  if (not defined $package)
  {
    Error("Handler for $type not properly configured (missing handler)");
    return 0;
  }
  my $handler = {};
  bless $handler, $package;
  $handler = $handler->new( $message->payload, $self->{&HANDLER}{$type} );
  if (not defined $handler)
  {
    Error("Failed to instantiate handler for $type");
    return 0;
  }

  if (not $handler->execute)
  {
    my $message_id = $message->header->get_message_id;
    Error("Unable to execute message #$message_id with handler for $type");
    return 0;
  }

  return 1;

}
#
#-------------------------------------------------------------------------------
#
sub queue #($)#
{
  Trace(Caller(undef, @_));
  my $self = shift;
  return $self->{&SQS_QUEUE};
}
#
#-------------------------------------------------------------------------------

#-------------------------------------------------------------------------------
#
$_set = sub #($$\$)#
{

  Trace(Caller('$_set', @_));
  my $self      = shift;
  my $section   = $_[0];
  my $parameter = $_[1];
  my $value     = $_[2];
  my $validator = $_[3];

  Confess( 'Missing section for _set'   ) unless defined $section;
  Confess( 'Missing parameter for _set' ) unless defined $parameter;
  Confess( 'Missing value for _set'     ) unless defined $value;
  Confess( 'Missing validator for _set' ) unless defined $validator;
  Confess( 'Invalid validator for _set' ) unless 'CODE' eq ref $validator;
  Confess( "Invalid parameter for _set: $parameter" )
    unless array_contains($DATA_SECTIONS{$section}, $parameter);
  return 0 unless &$validator($value);

  $self->{$section}{$parameter} = $value;
  $self->$_reset_queue if AWS eq $section
                       and defined $self->get_access_key
                       and defined $self->get_secret_key
                       and defined $self->get_queue_name;

  return 1;

};
#
#-------------------------------------------------------------------------------
#
sub get_access_key        { Trace(Caller(undef, @_));
                            return $_[0]->{ &AWS      }{ &ACCESS_KEY } }
sub get_database_host     { Trace(Caller(undef, @_));
                            return $_[0]->{ &DATABASE }{ &HOST       } }
sub get_database_port     { Trace(Caller(undef, @_));
                            return $_[0]->{ &DATABASE }{ &PORT       } }
sub get_database_username { Trace(Caller(undef, @_));
                            return $_[0]->{ &DATABASE }{ &USERNAME   } }
sub get_database_password { Trace(Caller(undef, @_));
                            return $_[0]->{ &DATABASE }{ &PASSWORD   } }
sub get_queue_name        { Trace(Caller(undef, @_));
                            return $_[0]->{ &AWS      }{ &QUEUE      } }
sub get_secret_key        { Trace(Caller(undef, @_));
                            return $_[0]->{ &AWS      }{ &SECRET_KEY } }
sub get_queue             { Trace(Caller(undef, @_));
                            return &queue(@_)                          }
#
#-------------------------------------------------------------------------------
#
sub set_access_key        { Trace(Caller(undef, @_));
                            return $_[0]->$_set( &AWS,      &ACCESS_KEY,
                                            $DATA_VALIDATE{ &ACCESS_KEY } ) }
sub set_database_host     { Trace(Caller(undef, @_));
                            return $_[0]->$_set( &DATABASE, &HOST,
                                            $DATA_VALIDATE{ &HOST       } ) }
sub set_database_port     { Trace(Caller(undef, @_));
                            return $_[0]->$_set( &DATABASE, &PORT,
                                            $DATA_VALIDATE{ &PORT       } ) }
sub set_database_username { Trace(Caller(undef, @_));
                            return $_[0]->$_set( &DATABASE, &USERNAME,
                                            $DATA_VALIDATE{ &USERNAME   } ) }
sub set_database_password { Trace(Caller(undef, @_));
                            return $_[0]->$_set( &DATABASE, &PASSWORD,
                                            $DATA_VALIDATE{ &PASSWORD   } ) }
sub set_queue_name        { Trace(Caller(undef, @_));
                            return $_[0]->$_set( &AWS,      &QUEUE,
                                            $DATA_VALIDATE{ &QUEUE      } ) }
sub set_secret_key        { Trace(Caller(undef, @_));
                            return $_[0]->$_set( &AWS,      &SECRET_KEY,
                                            $DATA_VALIDATE{ &SECRET_KEY } ) }
#
#-------------------------------------------------------------------------------


1;
__END__

=head1 NAME

Heedra - Heedra Queuing System

=head1 SYNOPSIS

Standard Usage

  use Heedra;
  $obj = Heedra->new();
  
  # Message Management
  $response = $obj->publish($message);
  $message  = $obj->consume();
  $bool     = $obj->delete_message($messge);
  
  # Queues
  $queue = $obj->queue();
  
  

Instantiation Options

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

