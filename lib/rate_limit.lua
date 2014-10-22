
function check_rate(target, rates)
  for __, rate in pairs(rates) do

    local max_hits = rate.hits + 1
    local throttle_time = rate.seconds
    local match = rate.match()

    -- how many hits we got on this match ?
    local stats = ngx.shared.stats
    local stats_key = target .. ":" .. match
    local hits = stats:get(stats_key)

    if not hits then
        stats:set(stats_key, 1, throttle_time)
    else
        hits = hits + 1
        stats:set(stats_key, hits, throttle_time)
        if hits >= max_hits then
            ngx.status = 429
            ngx.header.content_type = 'text/plain; charset=us-ascii'
            ngx.say(hits)
            ngx.say(max_hits)
            ngx.print("Rate limit exceeded.")
            ngx.exit(ngx.HTTP_OK)
        end
    end
  end
end


-- public interface
return {
  check_rate = check_rate
}
