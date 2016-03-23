package Heedra::Header;

use strict;
use warnings;
use Heedra::Log;
use Heedra::Utils qw( :valid );


################################################################################
#
my ($_init, $_set);
#
################################################################################
#
use constant
{
  CONSUME    => 'consume',
  HOST       => 'host',
  IP         => 'ip',
  MD5        => 'md5',
  MESSAGE_ID => 'message_id',
  PUBLISH    => 'publish',
  RECEIPT    => 'receipt_handle',
  TIMESTAMP  => 'timestamp',
  TYPE       => 'type',
};
#
################################################################################
#
my %MEMBER_VALIDATE;
   $MEMBER_VALIDATE{ &HOST       } = \&is_valid_host;
   $MEMBER_VALIDATE{ &IP         } = \&is_valid_ip;
   $MEMBER_VALIDATE{ &MD5        } = \&is_valid_md5;
   $MEMBER_VALIDATE{ &MESSAGE_ID } = \&is_valid_message_id;
   $MEMBER_VALIDATE{ &RECEIPT    } = \&is_valid_receipt_handle;
   $MEMBER_VALIDATE{ &TIMESTAMP  } = \&is_valid_timestamp;
   $MEMBER_VALIDATE{ &TYPE       } = \&is_valid_type;
#
################################################################################


#===============================================================================
#
sub new #(;%)#
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
$_init = sub #(;%)#
{

  Trace(Caller('$_init', @_));
  my $self = shift;
  my %data = @_;

  # Build Empty Structure
  $self->{ &CONSUME    }{ &HOST      } = undef;
  $self->{ &CONSUME    }{ &IP        } = undef;
  $self->{ &CONSUME    }{ &TIMESTAMP } = undef;
  $self->{ &MD5        }               = undef;
  $self->{ &MESSAGE_ID }               = undef;
  $self->{ &PUBLISH    }{ &HOST      } = undef;
  $self->{ &PUBLISH    }{ &IP        } = undef;
  $self->{ &PUBLISH    }{ &TIMESTAMP } = undef;
  $self->{ &RECEIPT    }               = undef;
  $self->{ &TYPE       }               = undef;

  foreach my $member (MD5, MESSAGE_ID, RECEIPT, TYPE)
  {
    next unless exists $data{$member};
    return undef
      unless $self->$_set(undef, $member, $data{$member});
  }
  foreach my $category (CONSUME, PUBLISH)
  {
    next unless exists $data{$category};
    foreach my $member (HOST, IP, TIMESTAMP)
    {
      next unless exists $data{$category}{$member};
      return undef
        unless $self->$_set($category, $member, $data{$member});
    }
  }

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
$_set = sub #($$$)#
{

  Trace(Caller('$_set', @_));
  my $self     = shift;
  my $category = $_[0];
  my $member   = $_[1];
  my $value    = $_[2];

  Fatal( 'Missing member for _set'   ) unless defined $member;
  Fatal( 'Invalid category for _set' ) unless not defined $category
                                           or CONSUME ne $category
                                           or PUBLISH ne $category;
  Fatal( 'Invalid member for _set'   ) unless exists $MEMBER_VALIDATE{$member};

  return 0 unless &{$MEMBER_VALIDATE{$member}}($value);

  if (defined $category)
  {
    $self->{$category}{$member} = $value;
  }
  else
  {
    $self->{$member} = $value;
  }

  return 1;

};
#
#-------------------------------------------------------------------------------
#
sub get_consume_host      { Trace(Caller(undef, @_));
                            return $_[0]->{ &CONSUME    }{ &HOST      }; }
sub get_consume_ip        { Trace(Caller(undef, @_));
                            return $_[0]->{ &CONSUME    }{ &IP        }; }
sub get_consume_timestamp { Trace(Caller(undef, @_));
                            return $_[0]->{ &CONSUME    }{ &TIMESTAMP }; }
sub get_md5               { Trace(Caller(undef, @_));
                            return $_[0]->{ &MD5        };               }
sub get_message_id        { Trace(Caller(undef, @_));
                            return $_[0]->{ &MESSAGE_ID };               }
sub get_receipt_handle    { Trace(Caller(undef, @_));
                            return $_[0]->{ &RECEIPT    };               }
sub get_publish_host      { Trace(Caller(undef, @_));
                            return $_[0]->{ &PUBLISH    }{ &HOST      }; }
sub get_puglish_ip        { Trace(Caller(undef, @_));
                            return $_[0]->{ &PUBLISH    }{ &IP        }; }
sub get_publish_timestamp { Trace(Caller(undef, @_));
                            return $_[0]->{ &PUBLISH    }{ &TIMESTAMP }; }
sub get_type              { Trace(Caller(undef, @_));
                            return $_[0]->{ &TYPE       };               }
#
#-------------------------------------------------------------------------------
#
sub set_consume_host      { Trace(Caller(undef, @_));
                            return $_[0]->$_set( CONSUME, HOST,       $_[1] ) }
sub set_consume_ip        { Trace(Caller(undef, @_));
                            return $_[0]->$_set( CONSUME, IP,         $_[1] ) }
sub set_consume_timestamp { Trace(Caller(undef, @_));
                            return $_[0]->$_set( CONSUME, TIMESTAMP,  $_[1] ) }
sub set_md5               { Trace(Caller(undef, @_));
                            return $_[0]->$_set( undef,   MD5,        $_[1] ) }
sub set_message_id        { Trace(Caller(undef, @_));
                            return $_[0]->$_set( undef,   MESSAGE_ID, $_[1] ) }
sub set_receipt_handle    { Trace(Caller(undef, @_));
                            return $_[0]->$_set( undef,   RECEIPT,    $_[1] ) }
sub set_publish_host      { Trace(Caller(undef, @_));
                            return $_[0]->$_set( PUBLISH, HOST,       $_[1] ) }
sub set_publish_ip        { Trace(Caller(undef, @_));
                            return $_[0]->$_set( PUBLISH, IP,         $_[1] ) }
sub set_publish_timestamp { Trace(Caller(undef, @_));
                            return $_[0]->$_set( PUBLISH, TIMESTAMP,  $_[1] ) }
sub set_type              { Trace(Caller(undef, @_));
                            return $_[0]->$_set( undef,   TYPE,       $_[1] ) }
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

