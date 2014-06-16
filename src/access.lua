--
-- To get this working you need to add the following in your
-- Nginx configuration
--
--  http {
--     lua_shared_dict  stats   10M;
--     server {
--        access_by_lua_file /path/to/access.lua;
--     }
--  }
--

local cjson = require "cjson"

-- config
-- we are allowing 10 hits per 10 seconds
local max_hits = 10
local throttle_time = 10

-- how many hits we got on this IP ?
local stats = ngx.shared.stats
local remote_ip = ngx.var.remote_addr
local hits = stats:get(remote_ip)

if hits == nil then
  stats:set(remote_ip, 1, throttle_time)
else
  hits = hits + 1
  stats:set(remote_ip, hits, throttle_time)
  if hits >= max_hits then
    -- 429 - Too many requests
    ngx.exit(429);
  end
end
