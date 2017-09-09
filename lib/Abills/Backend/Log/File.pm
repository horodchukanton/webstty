package Abills::Backend::Log::File;
use strict;
use warnings FATAL => 'all';

use AnyEvent;
use AnyEvent::Handle;

use POSIX qw/sprintf/;

use Abills::Backend::Log qw/:levels/;

my %file_handles = ();
#**********************************************************
=head2 new($file_qualifier, $current_level, $attr)

  Arguments:
    $file_qualifier
    $current_level
    $attr
    
  Returns:
    object
    
=cut
#**********************************************************
sub new {
  my $class = shift;
  
  my ($file_qualifier) = @_;
  
  $file_qualifier //= \*STDOUT;
  
  my $self = {
    file => $file_qualifier,
  };
  
  bless($self, $class);
  
  return $self;
}

#**********************************************************
=head2 log($time, $label, $level, $message)

  Arguments:
    $level, $label, $message -
    
  Returns:
  
=cut
#**********************************************************
sub log {
  my ($self, $time, $label, $level, $message) = @_;
  
  my $hdl = _get_handle_for_file($self->{file});
  
  $hdl->push_write(
    POSIX::sprintf(
      "[%s] [ %-10s ]%-6s: %s\n",
      $time,
      $label,
      $Abills::Backend::Log::STR_LEVEL{$level} // 'DEBUG',
      $message
    )
  );
}



#**********************************************************
=head2 _get_handle_for_file($file_name) -

  Arguments:
    $file_name -
    
  Returns:
  
  
=cut
#**********************************************************
#@returns AnyEvent::Handle
sub _get_handle_for_file {
  my ($file_name) = @_;
  
  if ( !$file_handles{$file_name} || $file_handles{$file_name}->destroyed() ) {
    
    my $log_fh;
    if ( !ref $file_name ) {
      open ($log_fh, '>>', $file_name) or die "Content-Type:text/html;\n\nCan't open $file_name : $@";
    }
    elsif ( ref $file_name eq 'GLOB' ) {
      $log_fh = $file_name
    }
    
    my AnyEvent::Handle $handle = AnyEvent::Handle->new(
      fh       => $log_fh,
      #      linger   => 1, # Allow write last data on destroy,
      autocork => 1,
      no_delay => 1,
      #      keepalive => 1,
      on_error => sub {
        print "Error on log ";
      }
    );
    
    $file_handles{$file_name} = $handle;
  }
  
  return $file_handles{$file_name};
}

1;