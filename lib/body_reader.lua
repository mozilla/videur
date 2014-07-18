--
-- body_reader
--
local util = require "util"
local len = string.len

function check_size(max_size)
    local content_length = tonumber(ngx.req.get_headers()['content-length'])
    local method = ngx.req.get_method()

    if not max_size then
        return
    end

    if content_length then
        if content_length > max_size then
            -- if the header says it's bigger we can drop now...
            ngx.exit(413)
        end
    end
    -- ...but we won't trust it if it says it's smaller
    local sock, err = ngx.req.socket()
    if not sock then
        if err == 'no body' then
            return
        else
            return util.bad_request(err)
        end
    end

    local chunk_size = 4096
    if content_length then
        if content_length < chunk_size then
            chunk_size = content_length
        end
    end

    sock:settimeout(0)

    -- reading the request body
    ngx.req.init_body(128 * 1024)
    local size = 0

    while true do
        if content_length then
            if size >= content_length then
                break
            end
        end
        local data, err, partial = sock:receive(chunk_size)
        data = data or partial
        if not data then
            return bad_request("Missing data")
        end


        ngx.req.append_body(data)
        size = size + len(data)

        if size >= max_size then
            ngx.exit(413)
        end

        local less = content_length - size
        if less < chunk_size then
            chunk_size = less
        end
    end
    ngx.req.finish_body()
end

-- public interface
return {
  check_size = check_size
}
