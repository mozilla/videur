# vi:filetype=

use lib 'lib';
use Test::Nginx::Socket;
use Cwd qw(cwd);

repeat_each(1);

plan tests => repeat_each() * blocks();
my $pwd = cwd();

our $HttpConfig = qq{
	lua_shared_dict stats 100k;
};


no_long_string();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: Lets call the dashboard
--- http_config eval: $::HttpConfig
--- config
    set $max_hits 2;
    set $throttle_time 10;
    set $script '../../lib/dashboard.lua';

    location /__dashboard__ {
        content_by_lua_file $script;
    }

--- request
    GET /__dashboard__
--- error_code: 200
