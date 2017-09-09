package Abills::Backend::Plugin::Websocket::API;
use strict;
use v5.16;
use warnings FATAL => 'all';

use Abills::Base qw/_bp/;

use Abills::Backend::Plugin::BaseAPI;
use parent 'Abills::Backend::Plugin::BaseAPI';

use Abills::Backend::Log;
our Abills::Backend::Log $Log;

my $log_user = ' Websocket::API ';

use Abills::Backend::Plugin::Websocket::SessionsManager;
use Abills::Backend::Defs;
use Abills::Backend::Utils qw/json_encode_safe json_decode_safe/;

=head2 NAME

  Abills::Backend::Plugin::Websocket::API

=head2 SYNOPSIS

  API for backend daemon plugins

=cut


#**********************************************************
=head2 new(\%session_managers) - constructor for Websocket API
  
  Attributes:
    \%session_managers -
    
  Returns:
    object - new Websocket API instance
  
=cut
#**********************************************************
sub new {
  state $instance;
  
  if ( !defined $instance ) {
    my $class = shift;
    my ($session_managers) = @_;
    
    my $self = {};
    bless($self, $class);
    
    $self->{session_managers} = $session_managers;
    
    $instance = $self;
  }
  
  return $instance;
}


#**********************************************************
=head2 notify_admin($aid, $notification, $attr) - sends notification to all admin handles

  Notify all sockets for this admin

=cut
#**********************************************************
sub notify_admin {
  my ($self, $aid, $notification, $attr) = @_;
  
  if ( !$aid || !$notification ) {
    $Log->info("Bad call of notify_admin. No " . (!$aid ? 'aid' : 'notification') . ' specified');
    return 0;
  };
  
  my $message = '';
  if ( ref $notification eq 'HASH' ) {
    $notification->{TYPE} //= 'MESSAGE';
    $message = json_encode_safe($notification)
  }
  else {
    $message = $notification;
  }
  
  # Handling JSON encode errors
  if ( !$message ) {
    $Log->info("Broken message. ignoring");
    return 0;
  }
  
  $Log->info("Admin($aid) message : " . $message);
  
  my Abills::Backend::Plugin::Websocket::SessionsManager $adminSessions = $self->{session_managers}->{admin};
  
  if ( $aid eq '*' ) {
    my $admins_to_notify = $adminSessions->get_all_clients();
    
    if ( $admins_to_notify && ref $admins_to_notify eq 'ARRAY' ) {
      $_->notify({ MESSAGE => $message, %{ $attr ? $attr : {} } }) foreach ( @{$admins_to_notify} );
    }
    else {
      $Log->alert("Trying to notify when no admins was online");
      return 0;
    }
    
    return 1;
  }
  
  my $Admin = $adminSessions->get_client_for_id($aid);
  if ( !$Admin ) {
    $Log->alert("Trying to notify when admin $aid was not online");
    return 0;
  };
  
  return $Admin->notify({ MESSAGE => $message, %{ $attr ? $attr : {} } });
}


#**********************************************************
=head2 admins_connected()

  Returns: arrayref of admin ids connected

=cut
#**********************************************************
sub admins_connected {
  my $self = shift;
  
  return $self->{session_managers}->{admin}->get_client_ids();
}

#**********************************************************
=head2 has_connected($type, $id) -

  Arguments:
    $type - admin | client
    $id   - aid | uid
    
  Returns:
    boolean
    
=cut
#**********************************************************
sub has_connected {
  my $self = shift;
  my ($type, $id) = @_;
  
  return $self->{session_managers}->{$type}->has_client_with_id($id);
}



1;