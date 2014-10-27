package = "Videur"
version = "0.1-1"

source = {
   url = "git://github.com/mozilla/videur",
   branch = "0.1.x",
}

description = {
   summary = "Web Application Firewall",
   detailed = [[
      Videur is a Lua library for OpenResty that will automatically
      parse an API specification file provided by a web server and
      proxy incoming Nginx requests to that server.
   ]],
   homepage = "https://github.com/mozilla/videur",
   license = "APLv2"
}

dependencies = {
   "lua >= 5.1",
   "luasec",
   "lua-resty-http",
   "lua-cjson",
   "lrexlib-posix",
   "date"
}

build = {
   type = "builtin",
   modules = {
     videur = "lib/videur.lua",
     body_reader = "lib/body_reader.lua",
     rate_limit = "lib/rate_limit.lua",
     spec_reader = "lib/spec_reader.lua",
     url = "lib/url.lua",
     util = "lib/util.lua"
   }
}
