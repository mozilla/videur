-- we're good, let's see if we're calling the dashboard
local lapis = require "lapis"
local app = lapis.Application()
local etlua = require "etlua"

app:enable("etlua")


function get_dirname()
  local sep = "/"
  local path = debug.getinfo(1).source:match("@(.*)$")
  return path:match("(.*"..sep..")")
end

__dir__ = get_dirname()


function load_template(filename)
  filename = __dir__ .. '/views/' ..  filename
  local f = assert(io.open(filename, "r"))
  local t = etlua.compile(f:read("*all"))
  f:close()
  return t
end


-- dashboard
app:get("/__dashboard__", function(self)
  local d = load_template("dashboard.etlua")
  return d()
  --return {render = d}
end)

lapis.serve(app)
