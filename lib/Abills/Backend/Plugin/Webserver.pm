package Abills::Backend::Plugin::Webserver;
use strict;
use warnings FATAL => 'all';
=head1 NAME

  Abills::Backend::Plugin::Webserver -

=head2 SYNOPSIS

  This package

=cut

use AnyEvent::Handle;
use AnyEvent::Socket;

our $Log;
use Abills::Backend::Defs;

#**********************************************************
=head2 new($CONF)

  Arguments:
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my ($CONF) = @_;
  
  my $self = {
    conf => $CONF,
    port => $CONF->{HTTP_PORT} || 8022,
    path => $CONF->{HTTP_PATH} || '/usr/webstty/public'
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 init($attr)

=cut
#**********************************************************
sub init {
  my ($self, $attr) = @_;
  
  my %conf = %{$self->{conf}};
  
  AnyEvent::Socket::tcp_server (0, $self->{port}, sub {
      $self->new_client_connection(@_);
    }
  );
  
  return $self;
  
  return 0;
}

#**********************************************************
=head2 new_client_connection($fh) -

  Arguments:
    $fh -
    
  Returns:
  
  
=cut
#**********************************************************
sub new_client_connection {
  my ($self, $socket_pipe_handle, $host, $port) = @_;
  
  my $handle = AnyEvent::Handle->new(
    fh        => $socket_pipe_handle,
    no_delay  => 1,
    keepalive => 1,
    autocork => 1,
    no_delay => 1,
    #    tls       => 'accept',
    #    tls_ctx   => {
    #      sslv3          => 0,
    #      verify         => 1,
    #      session_ticket => 1,
    #    },
  );
  
  # On message
  $handle->on_eof(
    sub {
      my AnyEvent::Handle $this_client_handle = shift;
      $this_client_handle->push_shutdown;
      $this_client_handle = undef;
    }
  );
  $handle->on_error(
    sub {
      my AnyEvent::Handle $read_handle = shift;
      $read_handle->push_shutdown;
      undef $handle;
    }
  );
  
  $handle->on_read(sub {
    my $fh = shift;
    my $chunk = $fh->{rbuf};
    undef $fh->{rbuf};
    
    
    my $path = _parse_http($chunk) || '/index.html';
    $Log->info("Request to $path");
    
    my $full_path = $self->{path} . '/' . $path;
    if ( -f $full_path ) {
      _serve_file($fh, $full_path);
    }
    else {
      $fh->push_write(qq{HTTP/1.1 404 Not found\nX-Requested : $full_path\n\n});
    }
    
    $fh->push_shutdown();
  });
}

#**********************************************************
=head2 _parse_http($request)

=cut
#**********************************************************
sub _parse_http {
  my ($request) = @_;
  $request =~ /^GET\s+([a-zA-Z.\/_=&+-]+)\s+HTTP\/1\.1\s+/;
  return $1 || 0;
}

#**********************************************************
=head2 _serve_file($client_fh, $file_path)

=cut
#**********************************************************
sub _serve_file {
  my ($client_fh, $file_path) = @_;
  
  my ($file_format) = $file_path =~ /\.([a-z]+)$/;
  
  $file_format //= 'default';
  
  my %format_content_type = (
    css       => 'text/css',
    js        => 'application/javascript',
    html      => 'text/html',
    'default' => 'text/plain'
  );
  
  $client_fh->push_write(
    qq{HTTP/1.1 200 OK
Connection: keep-alive
Content-Type: $format_content_type{$file_format}
X-Format:$file_format
}
  );
  
  open (my $fh, '<', $file_path) or return 0;
  my $content = '';
  while ( my $l = <$fh> ) {
    $content .= $l;
  }
  
  $client_fh->push_write("Content-Length:" . (length $content) . "\n\n");
  $client_fh->push_write($content);
  return 1;
}




1;