local etlua = require "etlua"
local http = require "resty.http"
local _url = require "url"


function get_dirname()
  local path = debug.getinfo(1).source:match("@(.*)$")
  return path:match("(.*/)")
end

local _dir = get_dirname()

function load_template(filename)
  filename = _dir .. '/views/' ..  filename .. ".etlua"
  local f = assert(io.open(filename, "r"))
  local t = etlua.compile(f:read("*all"))
  f:close()
  return t
end


function render_template(filename)
  return load_template(filename)()
end


function capture_errors(func)
  return function(self)
    local status, result = pcall(func, self)
    if not status then
      ngx.say(result)
      ngx.say(debug.traceback())
      return ngx.exit(512)
    else
      return result
    end
  end
end


function bad_request(message)
    ngx.status = 400
    ngx.say(message)
    return ngx.exit(ngx.HTTP_OK)
end


function fetch_http_body(url)
    url = _url.parse(url)
    local host = url.host
    local path = url.path
    local port = url.port
    local hc = http:new()

    hc:set_timeout(1000)
    ok, err = hc:connect(host, port)
    if not ok then
        ngx.say("failed to connect: ", err)
        return ''
    end

    local res, err = hc:request({ path = path })
    if not res then
        ngx.say("failed to retrieve: ", err)
        return ''
    end

    local body = res:read_body()
    local ok, err = hc:close()
    if not ok then
      ngx.say("failed to close: ", err)
    end

    return body
end


function Keys(list)
  local keys = {}
  for k, _ in pairs(list) do
    keys[k] = true
  end
  return keys
end


function size2int(size)
    if not size then
        return nil
    end
    assert(type(size) == "string", "size2int expects a string")
    size = size:lower()
    unit = size:sub(-1)
    if unit == 'k' then
        size = tonumber(size:sub(1, -2)) * 1024
    elseif unit == 'm' then
        size = tonumber(size:sub(1, -2)) * 1024 * 1024
    elseif unit == 'g' then
        size = tonumber(size:sub(1, -2)) * 1024 * 1024 * 1025
    else
        size = tonumber(size)
    end
    return size
end


-- tokenizes a set of rules and returns a Lua function that
-- can be used to extract an id from the current request
function compute_rules(str)
    tokens = {}
    for token in str:gmatch("%w+") do
        if token:gmatch("header:%w+") then
            token = 'ngx.req.get_headers()["' .. token:sub(1+len("header:")) .. '"])'
        else
            token = token:lower()
            if token == 'and' then
                token = ".. '++++' .. "
            elseif token == 'or' or token == '(' or token == ')' then
                -- plain or for now
                token = token
            elseif token == 'ipv4' or token == 'ipv6' then
                -- XXX do we want to split the X-Forwarded-For chain?
                token = '(ngx.var.http_x_forwarded_for or ngx.var.remote_addr)'
            else
                -- raise an error
                error("Invalid token: " .. token)
            end
        end
        tokens:insert(token)
    end

    return loadstring(tokens:concat(' '))
end


-- public interface
return {
  render_template = render_template,
  load_template = load_template,
  capture_errors = capture_errors,
  bad_request = bad_request,
  fetch_http_body = fetch_http_body,
  Keys = Keys,
  size2int = size2int,
  compute_rules = compute_rules
}
