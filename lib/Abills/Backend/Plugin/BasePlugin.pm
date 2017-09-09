package Abills::Backend::Plugin::BasePlugin;
use strict;
use warnings FATAL => 'all';

=head1 NAME

  Abills::Backend::BasePlugin - ierarchical parent for all Backend Plugins

=head2 SYNOPSIS

  This package defines and describes interface for Backend plugins

=cut

use Abills::Backend::Plugin::BaseAPI;

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
  };
  
  bless($self, $class);
  return $self;
}

#**********************************************************
=head2 init($attr)

  Init plugin (start servers, check params, etc)
  
  Returns:
    API to control plugin
    
=cut
#**********************************************************
sub init {
  my ($self, $attr) = @_;
  $self->{api} = Abills::Backend::Plugin::BaseAPI->new($self->{conf}, $attr);
  return $self->{api};
};

1;