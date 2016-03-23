package Heedra::Queue;

use strict;
use warnings;
use Amazon::SQS::Simple;
use Amazon::SQS::Simple::Message;
use Heedra::Log;
use Heedra::Message;
use Heedra::Utils qw( :valid );
use MIME::Base64;
use Socket;
use Storable qw( freeze thaw );
use Sys::Hostname;


################################################################################
#
my ($_init, $_set_queue);
$Carp::Internal{ (__PACKAGE__) }++;
#
################################################################################
#
use constant
{
  ACCESS_KEY => 'access_key',
  SECRET_KEY => 'secret_key',
  NAME       => 'name',
  SQS        => 'sqs',
  QUEUE      => 'queue',
};
#
################################################################################


#===============================================================================
#
sub new
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
$_init = sub #(@_)#
{

  Trace(Caller('$_init', @_));
  my $self = shift;
  my %data = @_;

  foreach my $required ( ACCESS_KEY, SECRET_KEY, NAME )
  {
    if (not exists $data{$required})
    {
      Error("Missing $required for " . __PACKAGE__ . ' creation');
      return undef;
    }
  }
  if (not $self->set_access_key($data{&ACCESS_KEY}))
  {
    Error('Invalid ' . ACCESS_KEY . ' for ' . __PACKAGE__ . 'creation');
    return undef;
  }
  if (not $self->set_secret_key($data{&SECRET_KEY}))
  {
    Error('Invalid ' . SECRET_KEY . ' for ' . __PACKAGE__ . 'creation');
    return undef;
  }
  if (not $self->set_name($data{&NAME}))
  {
    Error('Invalid ' . NAME . ' for ' . __PACKAGE__ . 'creation');
    return undef;
  }

  return $self;

};
#
#===============================================================================
#
$_set_queue = sub #()#
{

  Trace(Caller('$_set_queue', @_));
  my $self       = shift;
  my $access_key = $self->get_access_key;
  my $secret_key = $self->get_secret_key;
  my $name       = $self->get_name;

  return unless defined $access_key
            and defined $secret_key
            and defined $name;

  $self->{ &SQS   } = new Amazon::SQS::Simple($access_key, $secret_key);
  $self->{ &QUEUE } = $self->{&SQS}->CreateQueue($name);

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
  my $self    = shift;
  my $message = $_[0];

  if ( not exists $self->{ &SQS   } or not defined $self->{ &SQS   } or
       not exists $self->{ &QUEUE } or not defined $self->{ &QUEUE }  )
  {
    Fatal('Queue not set up for publishing');
  }
  if (not defined $message)
  {
    Error('Missing message for publish');
    return undef;
  }
  if ('Heedra::Message' ne ref $message)
  {
    Error('Invalid message for publish');
    return undef;
  }
  if (not defined $message->payload)
  {
    Error('Message does not have a valid payload');
    return undef;
  }
  Fatal('Message does not have a valid header')
    unless defined $message->header;

  # Update Header
  my $hostname = hostname;
  my $ip_inet  = gethostbyname $hostname;
  my $ip_addr  = inet_ntoa $ip_inet;
  $message->header->set_publish_host      ( $hostname );
  $message->header->set_publish_ip        ( $ip_addr  );
  $message->header->set_publish_timestamp ( time      );

  # Encode Message
  my $serialized = freeze($message);
  my $encoded    = encode_base64($serialized);

  Info('Publishing new message');

  return $self->{&QUEUE}->SendMessage($encoded);

}
#
#-------------------------------------------------------------------------------
#
sub consume ()
{

  Trace(Caller(undef, @_));
  my $self = shift;

  if ( not exists $self->{ &SQS   } or not defined $self->{ &SQS   } or
       not exists $self->{ &QUEUE } or not defined $self->{ &QUEUE }  )
  {
    Fatal('Queue not set up for publishing');
  }

  # Decode Message
  my $body = $self->{&QUEUE}->ReceiveMessage;
  return undef unless defined $body;

  my $frozen  = decode_base64($body->MessageBody);
  my $message = thaw($frozen);
  {
    my $ref = ref $message;
    Fatal("Invalid Message Type for consume: $ref")
      unless 'Heedra::Message' eq $ref;
  }

  # Update Header
  my $hostname = hostname;
  my $ip_inet  = gethostbyname $hostname;
  my $ip_addr  = inet_ntoa $ip_inet;
  $message->header->set_consume_timestamp ( time                 );
  $message->header->set_consume_host      ( $hostname            );
  $message->header->set_consume_ip        ( $ip_addr             );
  $message->header->set_md5               ( $body->MD5OfBody     );
  $message->header->set_message_id        ( $body->MessageId     );
  $message->header->set_receipt_handle    ( $body->ReceiptHandle );

  return $message;

}
#
#-------------------------------------------------------------------------------
#
sub delete_message #($)#
{

  Trace(Caller(undef, @_));
  my $self    = shift;
  my $message = $_[0];

  if (not defined $message)
  {
    Error('Missing Message for delete_message');
    return 0;
  }
  if (not ref $message or not $message->isa('Heedra::Message'))
  {
    Error('Invalid Message for delete_message');
    return 0;
  }
  if (not defined $message->header)
  {
    Error('Missing Message Header for delete_message');
    return 0;
  }
  if (not ref $message->header or not $message->header->isa('Heedra::Header'))
  {
    Error('Invalid Message Header for delete_message');
    return 0;
  }

  my $receipt = $message->header->get_receipt_handle;
  if (not is_valid_receipt_handle($receipt))
  {
    Error('Invalid Message Receipt Handle for delete_message');
    return 0;
  }

  my $message_id = $message->header->get_message_id;
  Info("Deleting Message $message_id from " . $self->get_name );
  $self->{&QUEUE}->DeleteMessage($receipt);
  return 1;

}
#
#-------------------------------------------------------------------------------
#
sub get_access_key ()
{
  Trace(Caller(undef, @_));
  my $self = shift;
  return (defined $self->{&ACCESS_KEY}) ? $self->{&ACCESS_KEY} : undef;
}
#
#-------------------------------------------------------------------------------
#
sub get_secret_key ()
{
  Trace(Caller(undef, @_));
  my $self = shift;
  return (defined $self->{&SECRET_KEY}) ? $self->{&SECRET_KEY} : undef;
}
#
#-------------------------------------------------------------------------------
#
sub get_name ()
{
  Trace(Caller(undef, @_));
  my $self = shift;
  return (defined $self->{&NAME}) ? $self->{&NAME} : undef;
}
#
#-------------------------------------------------------------------------------
#
sub set_access_key #($)#
{
  Trace(Caller(undef, @_));
  my $self = shift;
  my $data = $_[0];
  return 0 unless defined($data)
              and is_valid_access_key($data);
  $self->{&ACCESS_KEY} = $data;
  $self->$_set_queue;
  return 1;
}
#
#-------------------------------------------------------------------------------
#
sub set_secret_key #($)#
{
  Trace(Caller(undef, @_));
  my $self = shift;
  my $data = $_[0];
  return 0 unless defined($data)
              and is_valid_secret_key($data);
  $self->{&SECRET_KEY} = $data;
  $self->$_set_queue;
  return 1;
}
#
#-------------------------------------------------------------------------------
#
sub set_name #($)#
{
  Trace(Caller(undef, @_));
  my $self = shift;
  my $data = $_[0];
  return 0 unless defined($data)
              and $data =~ /^\S+$/;
  $self->{&NAME} = $data;
  $self->$_set_queue;
  return 1;
}
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

