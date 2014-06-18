# vi:filetype=

use lib 'lib';
use Test::Nginx::Socket;
use Cwd qw(cwd);

repeat_each(1);

plan tests => repeat_each() * blocks() * 6;
my $pwd = cwd();

our $HttpConfig = qq{
  lua_package_path "$pwd/lib/?.lua;;";
  lua_shared_dict stats 100k;
};

our $Config = qq{
  set \$max_hits 2;
  set \$throttle_time 10;
  access_by_lua_file '$pwd/lib/rate_limit.lua';

  location /hello {
    echo "hello";
  }

  location /world {
    echo "world";
  }
};

no_long_string();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: The third call should return a 429
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- request eval
    ["GET /hello", "GET /hello", "GET /world"]
--- error_code eval
    [200, 200, 429]
--- response_body_like eval
    ["hello.*", "hello.*", ""]
