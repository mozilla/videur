# vi:filetype=

use lib 'lib';
use Test::Nginx::Socket;
use Cwd qw(cwd);

repeat_each(1);

plan tests => repeat_each() * blocks() * 6;
my $pwd = cwd();

our $HttpConfig = qq{
	lua_shared_dict stats 100k;
};


no_long_string();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: The thirdt call should return a 429
--- http_config eval: $::HttpConfig
--- config
    set $max_hits 2;
    set $throttle_time 10;
    set $script '../../src/access.lua';
    access_by_lua_file $script;

    location /hello {
        echo "hello";
    }

    location /world {
        echo "world";
    }

--- request eval
    ["GET /hello", "GET /hello", "GET /world"]
--- error_code eval
    [200, 200, 429]
--- response_body_like eval
    ["hello.*", "hello.*", ""]
