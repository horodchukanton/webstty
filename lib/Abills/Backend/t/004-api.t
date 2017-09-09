#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
plan tests => 7;

our ($db, $admin, %conf);

if ( use_ok ('Abills::Backend::API') ) {
  require Abills::Backend::API;
  Abills::Backend::API->import()
};

my Abills::Backend::API $api = new_ok('Abills::Backend::API', [ $db, $admin, \%conf ]);

ok($api->is_connected, 'Connected to Internal server') || do {
  done_testing();
  exit 0
};

# Check we have 1 admin connected
my $is_admin_connected = $api->is_admin_connected(1);
ok($is_admin_connected, "Have admin 1 online");
# Try to ping admin 1
ok($api->call(1, '{"TYPE":"PING"}'), 'Ping admin 1');

ok(!$api->is_admin_connected(2), "Admin 2 should not be online");

# Try intensive ping
for ( 1 ... 100 ) {
  $api->is_admin_connected(1);
}
ok(1, "Alive after 100 pings");

done_testing();

1;