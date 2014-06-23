-- reads the proxy server specs to generate the actual routing
-- rejects anything that's not
local cjson = require "cjson"
local rex = require "rex_posix"
local util = require "_util"


local key = ngx.var.http_user_agent
if not key then
    return bad_request("no user-agent found")
end

local spec_url = ngx.var.spec_url
local cached_spec = ngx.shared.cached_spec
local last_updated = cached_spec:get("last-updated")

-- update the spec if needed
-- TODO: add a Last-Modified header + check every 5mn maybe
-- TODO: make sure it gets reloaded on sighup
local body, location, version, resources = nil


-- TODO: we need a way to invalidate the cache
if not last_updated then
    -- we need to load it from the backend
    body = util.fetch_http_body("http://127.0.0.1:8282/api-specs")
    cached_spec:set("raw_body", body)
    body = cjson.decode(body)    -- todo catch parse error

    -- grabbing the values and setting them in mem
    local service = body.service
    cached_spec:set('location', service.location)
    location = service.location
    version = service.version
    cached_spec:set('version', service.version)
    for location, desc in pairs(service.resources) do
      for verb, def in  pairs(desc) do
        local params = cjson.encode(def.parameters)
        cached_spec:set(verb .. ":" .. location, params)
      end
    end
    last_updated = os.time()
    cached_spec:set("last-updated", last_updated)
else
    location = cached_spec:get('location')
end

-- now let's see if we have a match
local method = ngx.req.get_method()
local key = method .. ":" .. ngx.var.uri
local cached_value = cached_spec:get(key)

if not cached_value then
    -- we don't!
    -- if we are serving / we can send back a page
    if ngx.var.uri == '/' then
        ngx.say("Welcome to Nginx/Videur")
        return ngx.exit(200)
    else
        return ngx.exit(ngx.HTTP_NOT_FOUND)
    end
end

-- we do, let's get the params
if method == 'GET' then
    local params = cjson.decode(cached_value)
    local args = ngx.req.get_uri_args()
    for key, val in pairs(args) do
       local constraint = params[key]
       if constraint then
           if not rex.match(val, constraint) then
             -- the value does not match the constraints
             return util.bad_request("Field does not match " .. key)
           end
       else
           -- this field was not declared
           return util.bad_request("Unknown field " .. key)
       end
    end
end

-- set the proxy_pass value
ngx.var.target = location
