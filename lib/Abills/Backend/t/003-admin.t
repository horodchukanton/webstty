#!/usr/bin/perl
use strict;
use warnings;
use Test::More tests => 1;

use Abills::Backend::Plugin::Websocket::Admin;

my $test_aid = 1;
my $test_chunk = qq{
Cookie: sid=testadmin1
};

my $authentification = Abills::Backend::Plugin::Websocket::Admin::authenticate($test_chunk);
ok($authentification == $test_aid, "Authenticated $test_aid as aid : $authentification");

my Abills::Backend::Plugin::Websocket::Admin $admin = Abills::Backend::Plugin::Websocket::Admin->new($test_aid);

done_testing();
