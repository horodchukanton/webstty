package Abills::Backend::Plugin::Websocket::Client;
use strict;
use warnings FATAL => 'all';

our (%conf, $base_dir, $debug, $ARGS, @MODULES);
use Abills::Backend::Log;
our Abills::Backend::Log $Log;

my $log_user = ' Websocket::Client ';

# Localizing global variables
use Abills::Backend::Defs;
use Abills::Base qw/_bp/;

use Abills::Backend::PubSub;

#**********************************************************
=head2 new($db, $admin, $CONF)

  Arguments:
    $db    - ref to DB
    $admin - current Web session admin
    $CONF  - ref to %conf
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my ($id) = @_;
  
  my $self = {
    id       => $id,
    sessions => {}
  };
  
  #  # Set handler that will destroy session if has
  #  $Pub->on('drop_client', sub {
  #      my $socket_id = shift;
  #      if ( exists $self->{sessions}->{$socket_id} ) {
  #        $self->{sessions}->{$socket_id}->kill()
  #      }
  #    });
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 save_handle($handle, $socket_id)

  Arguments:
    $handle, $socket_id -
    
  Returns:
     1
    
=cut
#**********************************************************
sub save_handle {
  my $self = shift;
  my ($handle, $socket_id) = @_;
  
  $self->{sessions}->{$socket_id} = Abills::Backend::Plugin::Websocket::Session->new($handle, $socket_id, $self->{id});
  
  $Log->debug("Saved handle for $socket_id. Total : " . scalar (keys %{ $self->{sessions} })) if ( $debug > 4 );
  
  #  print "Saved handle for $socket_id. Total : " . scalar (keys %{ $self->{sessions} }) . "\n";
  
  return 1;
}

#**********************************************************
=head2 remove_handle($socket_id, $reason) -

  Arguments:
    $socket_id -
    $reason    -
    
  Returns:
     -
    
=cut
#**********************************************************
sub remove_handle {
  my ($self, $socket_id, $reason) = @_;
  
  return 0 if ( !exists $self->{sessions}->{$socket_id} );
  
  $self->{sessions}->{$socket_id}->kill($reason);
  
  delete $self->{sessions}->{$socket_id};
  
  return 1;
}

#**********************************************************
=head2 kill($reason) - notify and remove

  Arguments:
    $reason -
    
  Returns:
    
    
=cut
#**********************************************************
sub kill {
  my $self = shift;
  my ($reason) = @_;
  
  foreach my $session ( values %{$self->{sessions}} ) {
    $session->kill($reason) if ( defined $session );
  }
  
  return;
}

#**********************************************************
=head2 has_session_for($socket_id)

  Arguments:
    $socket_id -
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub has_session_for {
  my ($self, $socket_id) = @_;
  
  return exists $self->{sessions}->{$socket_id};
}

#**********************************************************
=head2 get_handle_for($socket_id) - returns AnyEvent::Handle

  Arguments:
    $socket_id -
    
  Returns:
    AnyEvent::Handle
    
=cut
#**********************************************************
sub get_handle_for {
  my ($self, $socket_id) = @_;
  
  return $self->{sessions}->{$socket_id}->{handle};
}

#**********************************************************
=head2 notify($attr) -

  Arguments:
    $attr -
      MESSAGE
      
  Returns:
    depends on type of request
    
=cut
#**********************************************************
sub notify {
  my ($self, $attr) = @_;
  
  my @sessions = values %{$self->{sessions}};
  
  my $id = $self->{id};
  
  if ( $#sessions < 0 ) {
    $Log->error('No opened sockets for ' . $id);
    return undef;
  }
  
  $Log->info("Notifying client $id . Opened sockets:" . ($#sessions + 1));
  
  my @responces = ();
  foreach my $session ( @sessions ) {
    push @responces, $session->request($attr->{MESSAGE});
  }
  
  if ( scalar @responces > 0 ) {
    my %client_answer = (
      TYPE   => 'RESULT',
      RESULT => \@responces
    );
    
    return \%client_answer;
  }
  
  return;
}

1;