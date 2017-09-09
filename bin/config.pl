#!/usr/bin/perl

our %conf = ();
our $base_dir = '/usr/webtty/';

$conf{WEBSOCKET_ENABLED} = 1;
$conf{WEBSOCKET_DEBUG} = 7;
$conf{WEBSOCKET_DEBUG_FILE} = '/tmp/webstty.log';

1;