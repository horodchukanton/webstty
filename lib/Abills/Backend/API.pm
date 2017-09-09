package Abills::Backend::API;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Abills::Backend::API - API to Internal plugin

=head2 SYNOPSIS

  This package allows conenction and data exchange to Internal plugin

=cut

use AnyEvent::Socket;
use AnyEvent::Handle;
use Abills::Base qw/_bp in_array/;

use JSON qw//;

my $PING_REQUEST = { "TYPE" => "PING" };
my $PING_RESPONCE = { "TYPE" => "PONG" };

my JSON::XS $json = JSON->new->utf8(0)->allow_nonref(1);

#**********************************************************
=head2 new($CONF, $attr)

  Arguments:
    $CONF  - ref to %conf
    $attr

  Returns:
    object

=cut
#**********************************************************
sub new {
  my $class = shift;
  my ($conf, $attr) = @_;
  
  my $host = $attr->{HOST} || $conf->{WEBSOCKET_HOST} || '127.0.0.1';
  my $port = $attr->{WEBSOCKET_INTERNAL_PORT} || $conf->{WEBSOCKET_INTERNAL_PORT} || '19444';
  
  my $connection_host = $host . ':' . $port;
  
  my $self = {
    conf            => $conf,
    connection_host => $connection_host,
    host            => $host,
    port            => $port,
    token           => $attr->{WEBSOCKET_TOKEN} || $conf->{WEBSOCKET_TOKEN}
  };
  
  # Because of sync calls need to wait for connection
  my $connection_wait = AnyEvent->condvar;
  tcp_connect ($host, $port, sub {
      my ($fh) = @_;
      
      if ( !$fh ) {
        $connection_wait->send(0);
      }
      else {
        $connection_wait->send(AnyEvent::Handle->new(fh => $fh, no_delay => 1));
      }
    }
  );
  
  # Wait until got connection
  my $connection_socket = $connection_wait->recv;
  return 0 if ( !$connection_socket );
  
  $self->{fh} = $connection_socket;
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 is_connected() - check if connected to internal WebSocket server

=cut
#**********************************************************
sub is_connected {
  my ($self) = @_;
  
  my $response = $self->json_request({ MESSAGE => $PING_REQUEST });
  
  return 0 unless ( $response );
  
  return $response && $response->{TYPE} && $response->{TYPE} eq 'PONG';
}

#**********************************************************
=head2 is_admin_connected($aid) - pings admin browser tabs

  Arguments:
    $aid - AID
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub is_admin_connected {
  my ($self, $aid) = @_;
  return unless ( $aid );
  
  my $res = $self->json_request({
    MESSAGE => {
      TYPE => "MESSAGE",
      TO   => "ADMIN",
      ID   => $aid,
      DATA => {
        TYPE => q/PING/
      }
    }
  });
  
  #  RESULT:$VAR1 = {
  #    'RESULT' => [
  #      1
  #    ],
  #    'TYPE' => 'RESULT'
  #  };
  
  if ( $res && ref $res eq 'HASH' && $res->{RESULT} && scalar @{$res->{RESULT}} ) {
    # At least one tab responds for ping
    return grep {$_ == 1} @{$res->{RESULT}};
  }
  
  return 0;
}

#**********************************************************
=head2 call($aid, $message) - send message to Websocket and receive responce

  Arguments:
    $aid     - Admin ID
    $message - json
      DATA

  Returns:
    hash - responce

=cut
#**********************************************************
sub call {
  my $self = shift;
  my ($aid, $message, $attr) = @_;
  
  $attr->{MESSAGE} = {
    TYPE => 'MESSAGE',
    TO   => 'ADMIN',
    ID   => $aid,
    DATA => $message,
  };
  
  return $self->json_request($attr);
}

#**********************************************************
=head2 call_plugin($plugin, $data, $attr) - will call to plugin's process_internal_message and return result

  Arguments:
    $plugin - name of plugin ('Websocket', 'Telegram', 'Asterisk')
    $data   - hash_ref. payload, data that will be sent to plugin
    $attr   - Abills::Backend::API->_request params
    
  Returns:
    hash_ref or 0
    
=cut
#**********************************************************
sub call_plugin {
  my ($self, $plugin, $data, $attr) = @_;
  
  $attr->{MESSAGE} = {
    TYPE     => 'PROXY',
    PROXY_TO => $plugin,
    MESSAGE  => $data
  };
  
  return $self->json_request($attr);
}

#**********************************************************
=head2 json_request($attr) - simple alias to get perl structure as result

  Arguments:
    $attr - hash_ref
      MESSAGE - JSON string

  Returns:
    hash_ref - result
    undef on timeout

=cut
#**********************************************************
sub json_request {
  my $self = shift;
  my ($attr) = @_;
  
  if ( $attr->{ASYNC} ) {
    my $cb = $attr->{ASYNC};
    
    # Override function to make it receive perl structure
    $attr->{ASYNC} = sub {
      my $res = shift;
      $cb->($res ? safe_json_decode($res) : $res);
    };
  }
  
  #  _bp('', $attr, {TO_CONSOLE => 1});
  $attr->{RETURN_RESULT} = 1;
  my $responce = $self->_request($attr, $attr->{MESSAGE});
  
  return 0 if ( !$responce || $responce eq q{"0"} );
  return safe_json_decode($responce);
}


#**********************************************************
=head2 _request($attr) - Request types wrapper

  Arguments:
    $attr -
      NON_SAFE
      ASYNC
      RETURN_RESULT
      
  Returns:
  
  
=cut
#**********************************************************
sub _request {
  my ($self, $attr, $payload) = @_;
  
  if ( $attr->{NON_SAFE} ) {
    return $self->_instant_request({
      MESSAGE => $payload,
      SILENT  => 1
    });
  }
  elsif ( $attr->{ASYNC} && ref $attr->{ASYNC} ) {
    $self->_asynchronous_request({
      MESSAGE  => $payload,
      CALLBACK => $attr->{ASYNC},
    });
    return;
  }
  
  my $sended = $self->_synchronous_request({
    MESSAGE => $payload
  });
  
  return ($attr->{RETURN_RESULT}) ? $sended : defined $sended;
}

#**********************************************************
=head2 _asynchronous_request($attr) - will write to socket and run callback, when receive result

  Arguments:
    $attr - hash_ref
      MESSAGE  - text will be send to backend server
      CALLBACK - function($result)
        $result will be
          string - if server responded with message
          ''     - if server accepted message, but not responded nothing
          undef  - if timeout

  Returns:
    undef
    

=cut
#**********************************************************
sub _asynchronous_request {
  my ($self, $attr) = @_;
  
  my $callback_func = $attr->{CALLBACK};
  my $message = $attr->{MESSAGE};
  
  my AnyEvent::Handle $handle = $self->{fh};
  
  # Setup recieve callback
  $handle->on_read(
    sub {
      my ($responce_handle) = shift;
      
      my $readed = $responce_handle->{rbuf};
      $responce_handle->{rbuf} = undef;
      
      $callback_func->($readed);
    }
  );
  
  $handle->push_write($message);
  
  return 1;
}

#**********************************************************
=head2 _synchronous_request($attr)

  Arguments:
    $attr - hash_ref
      MESSAGE - text will be send to backend server

  Returns:
    string - if server responded with message
    ''     - if server accepted message, but not responded nothing
    undef  - if timeout

=cut
#**********************************************************
sub _synchronous_request {
  my ($self, $attr) = @_;
  
  my $message = $attr->{MESSAGE} || do {
    warn 'No $attr->{MESSAGE} in WebSocket::API ' . __LINE__ . " \n";
    return 0;
  };
  
  my AnyEvent::Handle $handle = $self->{fh};
  
  # Setup recieve callback
  my $operation_end_waiter = AnyEvent->condvar;
  $handle->on_read(
    sub {
      my ($responce_handle) = shift;
      
      my $readed = $responce_handle->{rbuf};
      $responce_handle->{rbuf} = undef;
      
      $operation_end_waiter->send($readed);
    }
  );
  
  # Set timeout to 2 seconds
  my $timeout_waiter = AnyEvent->timer(
    after => 2,
    cb    => sub {
      _bp("Abills::Sender::Browser", "$self->{host} Timeout", { TO_CONSOLE => 1 }) if ( $self->{debug} );
      $operation_end_waiter->send(undef);
    }
  );
  
  $handle->push_write($json->encode($message));
  
  # Script will hang here until receives result from async operation above
  my $result = $operation_end_waiter->recv;
  
  return $result;
};

#**********************************************************
=head2 _instant_request($attr) - will not wait for timeout, but no warranties for receive

  Arguments:
    $attr - hash_ref
      MESSAGE - text will be send to backend server

  Returns:
    1
    
=cut
#**********************************************************
sub _instant_request {
  my $self = shift;
  my ($attr) = @_;
  
  $self->{fh}->push_write($json->encode($attr));
  
  return 1;
}

#**********************************************************
=head2 safe_json_decode($json_string)

=cut
#**********************************************************
sub safe_json_decode {
  my $str = shift;
  
  return $str if ( ref $str );
  
  my $res = '';
  eval {$res = $json->decode($str)};
  if ( $@ ) {
    return "Error parsing JSON: $@. \n Got: " . ($str // '') . " at " . join(', ', caller[ 0, 2 ]);
  }
  
  return $res;
}

1;