-- reads the proxy server specs to generate the actual routing
-- rejects anything that's not
local cjson = require "cjson"
local http = require "resty.http"
local rex = require "rex_posix"

local key = ngx.var.http_user_agent
if not key then
    ngx.log(ngx.ERR, "no user-agent found")
    return ngx.exit(400)
end

local spec_url = ngx.var.spec_url
local cached_spec = ngx.shared.cached_spec
local last_updated = cached_spec:get("last-updated")


local function bad_request(message)
    ngx.status = 400
    ngx.say(message)
    return ngx.exit(ngx.HTTP_OK)
end

--
--  reads an url synchronously
--
local function get_body(host, port, path)
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

-- update the spec if needed
-- TODO: add a Last-Modified header + check every 5mn maybe
-- TODO: make sure it gets reloaded on sighup
local body, location, version, resources = nil

if true then
   --if not last_updated then
    -- we need to load it from the backend
    body = get_body("127.0.0.1", 8282, "/api-specs")
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
             return bad_request("Field does not match " .. key)
           end
       else
           -- this field was not declared
           return bad_request("Unknown field " .. key)
       end
    end
end

-- set the proxy_pass value
ngx.var.target = location
