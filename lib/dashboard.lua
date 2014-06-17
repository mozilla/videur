-- we're good, let's see if we're calling the dashboard
local lapis = require "lapis"
local util = require "_util"
local app = lapis.Application()


-- dashboard
app:get("/__dashboard__", util.capture_errors(function(self)
  return util.render_template("dashboard")
end))


lapis.serve(app)
