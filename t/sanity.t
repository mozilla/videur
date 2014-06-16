# vi:filetype=

use lib 'lib';
use Test::Nginx::Socket;
use Cwd qw(cwd);


repeat_each(1);

plan tests => repeat_each() * blocks() * 4;
my $pwd = cwd();

our $HttpConfig = qq{
	lua_shared_dict stats 100k;
};


no_long_string();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: Just to make sure we know how to make tests
--- http_config eval: $::HttpConfig
--- config
    set $max_hits '1';
    set $throttle_time '10';
    set $script '../../src/access.lua';

    location /echo {
        access_by_lua_file $script;
        echo "hello";
    }

--- request eval
    ["GET /echo", "GET /echo"]
--- error_code eval
    [200, 429]
--- response_body_like eval
    ["hello.*", ""]
