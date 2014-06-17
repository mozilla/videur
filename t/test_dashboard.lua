# vi:filetype=
use lib 'lib';
use Test::Nginx::Socket;
use Cwd qw(cwd);

$ENV{PWD} = cwd();

repeat_each(1);
plan tests => repeat_each() * blocks() * 2;
no_long_string();
no_shuffle();

my $pwd = cwd();

our $HttpConfig = qq{
  lua_package_path "$pwd/lib/?.lua;;";
};

our $Config = qq{
  location /__dashboard__ {
    content_by_lua_file '$pwd/lib/dashboard.lua';
  }
};


run_tests();

__DATA__

=== TEST 1: Lets call the dashboard
--- http_config eval: $::HttpConfig
--- config eval: $::Config
--- request
    GET /__dashboard__
--- error_code: 200
--- response_body_like
.*Hello.*
