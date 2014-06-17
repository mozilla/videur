# vi:filetype=
use lib 'lib';
use Test::Nginx::Socket;

repeat_each(1);
plan tests => repeat_each() * blocks() * 2;
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: Lets call the dashboard
--- config
    set $script '../../lib/dashboard.lua';

    location /__dashboard__ {
        content_by_lua_file $script;
    }

--- request
    GET /__dashboard__
--- error_code: 200
--- response_body_like
.*Hello.*
