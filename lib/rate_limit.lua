-- load the config
local max_hits = tonumber(ngx.var.max_hits) + 1
local throttle_time = tonumber(ngx.var.throttle_time)

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
    ngx.status = 404
    ngx.header.content_type = 'text/plain; charset=us-ascii'
    ngx.print("Rate limit exceeded.")
    ngx.exit(ngx.HTTP_OK)
  end
end

return ngx.exit(ngx.OK)
