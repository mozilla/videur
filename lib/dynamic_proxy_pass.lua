
-- reads the proxy server specs to generate the actual routing
-- rejects anything that's not
local cjson = require "cjson"
local rex = require "rex_posix"
local util = require "_util"


local cached_spec = ngx.shared.cached_spec


function get_location()
    local spec_url = ngx.var.spec_url or "http://127.0.0.1:8282/api-specs"
    local last_updated = cached_spec:get("last-updated")

    -- update the spec if needed
    -- TODO: add a Last-Modified header + check every 5mn maybe
    -- TODO: make sure it gets reloaded on sighup


    -- TODO: we need a way to invalidate the cache
    if not last_updated then
        local body, version, resources = nil
        -- we need to load it from the backend
        body = util.fetch_http_body(spec_url)
        cached_spec:set("raw_body", body)
        body = cjson.decode(body)    -- todo catch parse error

        -- grabbing the values and setting them in mem
        local service = body.service
        cached_spec:set('location', service.location)
        version = service.version
        cached_spec:set('version', service.version)
        for location, desc in pairs(service.resources) do
        for verb, def in pairs(desc) do
            local params = cjson.encode(def.parameters or {})
            cached_spec:set(verb .. ":" .. location, params)
        end
        end
        last_updated = os.time()
        cached_spec:set("last-updated", last_updated)
        return service.location
    else
        return cached_spec:get('location')
    end
end


function match()
    -- get the location frmo the specs
    local location = get_location()

    -- now let's see if we have a match
    local method = ngx.req.get_method()
    local key = method .. ":" .. ngx.var.uri
    local cached_value = cached_spec:get(key)

    if not cached_value then
        -- we don't!
        -- if we are serving / we can send back a page
        -- TODO: whitelist of URLS ?
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

        -- let's check if we have all required args first
        local provided_args = util.Keys(args)

        for key, value in pairs(params) do
            if value.required and not provided_args[key] then
                return util.bad_request("Missing " .. key)
            end
        end

        -- now let's validate the args we got
        for key, val in pairs(args) do
        local constraint = params[key]
        if constraint then
            if constraint['validation'] then
                if not rex.match(val, constraint['validation']) then
                    -- the value does not match the constraints
                    return util.bad_request("Field does not match " .. key)
                end
            end
        else
            -- this field was not declared
            return util.bad_request("Unknown field " .. key)
        end
        end
    end -- end if GET

    return location
end


-- main code

-- abort if we don't have any use agent
local key = ngx.var.http_user_agent
if not key then
    return bad_request("no user-agent found")
end

-- set the proxy_pass value by matching
-- the request against the api specs
ngx.var.target = match()
