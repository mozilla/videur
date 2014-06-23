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



-- public interface
return {
  render_template = render_template,
  load_template = load_template,
  capture_errors = capture_errors,
  bad_request = bad_request,
  fetch_http_body = fetch_http_body
}
