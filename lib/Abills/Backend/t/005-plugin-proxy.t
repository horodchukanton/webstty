#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Abills::Base qw/_bp/;

plan tests => 6;

_bp('', '', { SET_ARGS => { TO_CONSOLE => 1 } });
our ($db, $admin, %conf);

use_ok 'Abills::Backend::API';
require Abills::Backend::API;
Abills::Backend::API->import();

my Abills::Backend::API $api = new_ok('Abills::Backend::API', [ $db, $admin, \%conf ]);

select STDERR;
my $call_unexistent_result = $api->call_plugin('Unexistent', { DATA => 'Whatever' });
ok ($call_unexistent_result->{ERROR}, 'Call to unexistent should return error');

my $echo_string = 123;
my $echo_result = $api->call_plugin('Internal', { ECHO => $echo_string });

ok($echo_result, 'Called echo without error');
ok($echo_result eq $echo_string, 'Echo returns requested string');

my $call_unimplemented = $api->call_plugin('Websocket', { DATA => 'Whatever' });
ok($call_unimplemented->{ERROR} && $call_unimplemented->{ERROR} eq "NOT IMPLEMENTED",
  'Not implemented returns "NOT IMPLEMENTED"'
);

select STDIN;

done_testing();

