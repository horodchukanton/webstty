package Abills::Backend::Plugin::Websocket;
use strict;
use warnings FATAL => 'all';
use feature 'say';

our (%conf, $base_dir, $debug, $ARGS, @MODULES);

use Abills::Backend::Plugin::BasePlugin;
use parent 'Abills::Backend::Plugin::BasePlugin';

use Abills::Backend::Log;
our Abills::Backend::Log $Log;

use Abills::Backend::PubSub;
our Abills::Backend::PubSub $Pub;

# Localizing global variables
use Abills::Backend::Defs;
use Abills::Base qw/_bp/;

use Abills::Backend::Plugin::Websocket::API;
use Abills::Backend::Plugin::Websocket::SessionsManager;
use Abills::Backend::Plugin::Websocket::Admin;
use Abills::Backend::Utils qw/json_decode_safe json_encode_safe/;

use Protocol::WebSocket::Handshake::Server;
use Protocol::WebSocket::Frame;

use AnyEvent::Open3::Simple;
use Expect;

use POSIX qw/sprintf/;

#my %sessionManagers = (
#  admin  => Abills::Backend::Plugin::Websocket::SessionsManager->new({ CLIENT_CLASS => 'Admin' }),
#  client => Abills::Backend::Plugin::Websocket::SessionsManager->new({ CLIENT_CLASS => 'Client' })
#);

our Abills::Backend::Plugin::Websocket::SessionsManager $adminSessions;
our Abills::Backend::Plugin::Websocket::SessionsManager $clientSessions;

my $OPCODE_CLOSE = 0x8;
my $OPCODE_PING = 0x9;
my $OPCODE_PONG = 0xA;

my $api;

#**********************************************************
=head2 new($conf) - constructor for Abills::Backend::Plugin::Websocket

=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my ($db, $admin, $CONF) = @_;
  
  my $self = {
    db    => $db,
    admin => $admin,
    conf  => $CONF,
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 init($attr)

  Arguments:
     $attr - reserved
    
  Returns:
    1
  
=cut
#**********************************************************
sub init {
  my ($self, $attr) = @_;
  
  # Starting websocket server
  $Log->info("Starting WebSocket server");
  
  $self->{session_managers} = {
    admin  => Abills::Backend::Plugin::Websocket::SessionsManager->new({ CLIENT_CLASS => 'Admin' }),
    client => Abills::Backend::Plugin::Websocket::SessionsManager->new({ CLIENT_CLASS => 'Client' })
  };
  
  $adminSessions = $self->{session_managers}->{admin};
  $clientSessions = $self->{session_managers}->{client};
  
  AnyEvent::Socket::tcp_server(0, $conf{WEBSOCKET_PORT} || 19443, sub {
      $self->new_admin_websocket_client(@_);
    });
  
  
  #  $self->_register_listeners();
  
  $api = Abills::Backend::Plugin::Websocket::API->new($self->{session_managers});
  
  return $api;
}

#**********************************************************
=head2 _register_listeners()

=cut
#**********************************************************
sub _register_listeners {
  my ($self) = @_;
  
}

#**********************************************************
=head2 new_admin_websocket_client()

=cut
#**********************************************************
sub new_admin_websocket_client {
  my ($self, $socket_pipe_handle, $host, $port) = @_;
  
  my $socket_id = "$host:$port";
  $Log->debug("Admin connection : $socket_id");
  
  my $handshake = Protocol::WebSocket::Handshake::Server->new;
  
  my $handle = AnyEvent::Handle->new(
    fh       => $socket_pipe_handle,
    no_delay => 1
  );
  
  # On message
  $handle->on_read(
    sub {
      my AnyEvent::Handle $this_client_handle = shift;
      
      # Read and clear read buffer
      my $chunk = $this_client_handle->{rbuf};
      $this_client_handle->{rbuf} = undef;
      
      # If it is handshake, do all protocol related stuff
      if ( !$handshake->is_done ) {
        $self->_do_handshake($this_client_handle, $chunk, $handshake);
        
        my $aid = 1;
        $Log->debug("Authorized admin $aid ");
        $adminSessions->save_handle($handle, $socket_id, $aid);
        
        return;
        
      }
      else {
        $self->on_websocket_message($this_client_handle, $socket_id, $chunk);
      }
    }
  );
  
  # On close
  $handle->on_eof(
    sub {
      $self->{$socket_id}->{console_mode} = 0;
      $Log->debug("$socket_id EOF");
      
      # Try to do it "good way"
      unless ( $adminSessions->remove_session_by_socket_id($socket_id) ) {
        # And otherwise kick it's face
        $handle->destroy;
        undef $handle;
      }
    }
  );
  
  $handle->on_error(
    sub {
      my AnyEvent::Handle $read_handle = shift;
      
      undef $self->{$socket_id}->{console_mode};
      $Log->debug("Error happened with admin $socket_id ");
      
      return unless ( defined $read_handle );
      $read_handle->push_shutdown;
      $read_handle->destroy;
      
      undef $handle;
    }
  )
};


#**********************************************************
=head2 on_websocket_message($read_handle)

=cut
#**********************************************************
sub on_websocket_message {
  my ( $self, $this_client_handle, $socket_id, $chunk) = @_;
  
  my $frame = Protocol::WebSocket::Frame->new;
  
  $frame->append($chunk);
  
  while ( my $message = $frame->next ) {
    my $opcode = $frame->opcode;
    
    # Client breaks connection
    if ( $opcode == $OPCODE_CLOSE ) {
      #$message eq "\x{3}\x{fffd}" || $frame->opcode == 8) {
      #      $Log->debug( "Client $socket_id breaks connection" );
      $adminSessions->remove_session_by_socket_id($socket_id, "Client $socket_id breaks connection");
      return;
    };
    
    if ( $opcode == $OPCODE_PING || $opcode == $OPCODE_PONG ) {
      # Todo treat as alive
      return;
    }
    
    if ( $self->{$socket_id}->{console_mode} ) {
      if ( $message eq qq/{"TYPE":"CONSOLE_CLOSE"}/ ) {
        my $response_text = '{"TYPE":"RESPONCE","RESULT":"OK"}';
        
        $self->exit_console_mode($socket_id);
        $Log->notice("Console mode off");
        
        $this_client_handle->push_write($frame->new($response_text)->to_bytes);
        
        return;
      }
      
      return $self->proxy_to_console($socket_id, $message);
    }
    
    my $decoded_message = json_decode_safe($message);
    
    if ( !$decoded_message ) {
      $Log->debug("Bad JSON");
      return;
    }
    
    if ( defined $decoded_message && ref $decoded_message eq 'HASH' && $decoded_message->{TYPE} ) {
      
      if ( $decoded_message->{TYPE} eq 'CLOSE_REQUEST' ) {
        $self->drop_client($socket_id, 'by client request');
      }
      elsif ( $decoded_message->{TYPE} eq 'PONG' ) {
        # Do nothing TODO: Treat as alive
        return;
      }
      elsif ( $decoded_message->{TYPE} eq 'RESPONCE' ) {
        # Do nothing TODO: Treat as alive
        return;
      }
      elsif ( $decoded_message->{TYPE} eq 'CONSOLE_REQUEST' ) {
  
        my $responce_text = '';
        if ($self->start_console_mode($socket_id)){
          $responce_text = '{"TYPE":"RESPONCE","RESULT":"OK"}';
          print "Console mode on\n";
        }
        else {
          $responce_text =  '{"TYPE":"ERROR","ERROR":"UNKNOWN ERROR"}';
        }
        
        $this_client_handle->push_write($frame->new($responce_text)->to_bytes);
        
      }
      else {
        my %response;
        
        # TODO: define message hadlers for types
        if ( $decoded_message->{TYPE} eq 'PING' ) {
          %response = (DATA => 'RESPONCE', TYPE => 'PONG');
        }
        else {
          %response = (DATA => $decoded_message);
        }
        
        #        my $response_text = json_encode_safe( process_message( \%response ) );
        my $response_text = json_encode_safe(\%response);
        
        $this_client_handle->push_write($frame->new($response_text)->to_bytes);
      }
    }
  }
  
}


#**********************************************************
=head2 drop_client($socket_id, $reason)

=cut
#**********************************************************
sub drop_client {
  my ($self, $socket_id, $reason) = @_;
  
  foreach ( values %{$self->{session_managers}} ) {
    my Abills::Backend::Plugin::Websocket::SessionsManager $sessions_manager = $_;
    if ( $sessions_manager->has_client_with_socket_id($socket_id) ) {
      $sessions_manager->remove_session_by_socket_id($socket_id, $reason);
      last;
    }
  }
  
}

#**********************************************************
=head2 drop_all_clients($reason)

=cut
#**********************************************************
sub drop_all_clients {
  my ($self, $reason) = shift;
  
  foreach ( values %{$self->{session_managers}} ) {
    my Abills::Backend::Plugin::Websocket::SessionsManager $sessions_manager = $_;
    $sessions_manager->drop_all_clients($reason);
  }
  
  return 1;
}

#**********************************************************
=head2 _do_handshake()

=cut
#**********************************************************
sub _do_handshake {
  my ($self, $this_client_handle, $chunk, $handshake) = @_;
  
  $handshake->parse($chunk);
  
  if ( $handshake->is_done ) {
    $this_client_handle->push_write($handshake->to_string);
    return 1;
  }
  
  return 0;
}


#**********************************************************
=head2 start_console_mode($socket_id) - starts console process

  Arguments:
    $socket_id -
    
  Returns:
    process STDOUT
    
=cut
#**********************************************************
sub start_console_mode {
  my ($self, $socket_id) = @_;
  
  my $this_client_handle = $adminSessions->get_handle_by_socket_id($socket_id);
  return if (!$socket_id || !$this_client_handle);
  
  # Create pipe
#  `[ -f ./console_1 ] && /usr/bin/mkfifo ./console_1`;
#  open(my $fifo, '>', "./console_1") or do {
#    $Log->alert("Can't open ./console_1");
#    return undef;
#  };
  
  my $err = '';
  my $ipc = AnyEvent::Open3::Simple->new(
    on_start  => sub {
      my $proc = shift;       # isa AnyEvent::Open3::Simple::Process
      my $program = shift;    # string
      my @args = @_;          # list of arguments
      say 'child PID: ', $proc->pid;
      
      $self->{$socket_id}->{console_mode} = $proc;
      
    },
    on_stdout => sub {
      my $proc = shift;       # isa AnyEvent::Open3::Simple::Process
      my $line = shift;       # string
      $Log->notice("stdout : '$line'");
      my $frame = Protocol::WebSocket::Frame->new;
      $this_client_handle->push_write($frame->new($line)->to_bytes);
      
    },
    on_stderr => sub {
      my $proc = shift;       # isa AnyEvent::Open3::Simple::Process
      my $line = shift;       # string
      $Log->notice("stderr : '$line'");
      my $frame = Protocol::WebSocket::Frame->new;
      $this_client_handle->push_write($frame->new($line)->to_bytes);
      $self->exit_console_mode($socket_id);
    },
    on_exit   => sub {
      my $proc = shift;       # isa AnyEvent::Open3::Simple::Process
      my $exit_value = shift; # integer
      my $signal = shift;     # integer
      $Log->error ("Console exit with : " . $signal);
    },
    on_error  => sub {
      my $error = shift;      # the exception thrown by IPC::Open3::open3
      my $program = shift;    # string
      $Log->error ("$program exits with error $err");
      $self->exit_console_mode($socket_id);
    },
  ) or $err = "Can't open IPC $!";
  
  $ipc->run('/bin/bash') or $err = "Can't start /bin/bash : $!";
  
  return $err ? 0 : 1;
}


#**********************************************************
=head2 proxy_to_console($socket_id, $message) - proxy_to_console_handler

  Arguments:
    $message -
    
  Returns:
    undef
    
=cut
#**********************************************************
sub proxy_to_console {
  my ($self, $socket_id, $message) = @_;
  return unless $socket_id && $message;
  
  my $ipc_process = $self->{$socket_id}->{console_mode};
  
  $Log->notice("Received '$message'");
  
  if ( $message =~ /^\d+$/ ) {
    # Transform key code to char
    my $char = chr($message);
    $message = $char;
  }
  
  $Log->notice("Will send: /  $message  /");
  my $child_stdin = $ipc_process->{stdin};
  
  $child_stdin->print($message);
  $child_stdin->flush();
  
  return;
}

#**********************************************************
=head2 exit_console_mode($socket_id) - removes temprorary files and goes back to normal mode

  Arguments:
    $socket_id -
    
  Returns:
  
  
=cut
#**********************************************************
sub exit_console_mode {
  my ($self,  $socket_id) = @_;
  
  return if (!$socket_id || !$self->{$socket_id}{console_mode});
  
  $self->{$socket_id}{console_mode}->close();
  undef $self->{$socket_id}{console_mode};
  
  return 1;
}

DESTROY {
  $Log->info("Websocket server stopped") if ( $Log );
}

1;