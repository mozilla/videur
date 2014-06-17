-- we're good, let's see if we're calling the dashboard
local lapis = require "lapis"
local app = lapis.Application()

app:match("/__dashboard__", function(self)
  return "Welcome!"
end)

return app
