# vi:filetype=

use lib 'lib';
use Test::Nginx::Socket;

repeat_each(1);

plan tests => repeat_each() * blocks() * 2;
no_long_string();
no_shuffle();
run_tests();

__DATA__

=== TEST 1: Just to make sure we know how to make tests
--- config

    location /echo {
      echo "hello";
    }

--- request
    GET /echo

--- error_code: 200
--- response_body
hello
