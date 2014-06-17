local etlua = require "etlua"


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


-- public interface
return {
  render_template = render_template,
  load_template = load_template,
  capture_errors = capture_errors
}
