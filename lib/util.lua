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


function implode(delimiter, list)
  local len = #list
  if len == 0 then
    return ""
  end
  local string = list[1]
  for i = 2, len do
    string = string .. delimiter .. list[i]
  end
  return string
end


function explode(delimiter, text)
  local list = {}
  local pos = 1

  if string.find("", delimiter, 1) then
    error("delimiter matches empty string!")
  end
  while 1 do
    local first, last = string.find(text, delimiter, pos)
    print (first, last)
    if first then
      table.insert(list, string.sub(text, pos, first-1))
      pos = last+1
    else
      table.insert(list, string.sub(text, pos))
      break
    end
  end
  return list
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
  implode = implode,
  explode = explode
}
