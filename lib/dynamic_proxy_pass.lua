
-- reads the proxy server specs to generate the actual routing
-- rejects anything that's not
local cjson = require "cjson"
local rex = require "rex_posix"
local util = require "_util"
local cached_spec = ngx.shared.cached_spec
local date = require "date"
local len = string.len


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
                local definition = cjson.encode(def or {})
                cached_spec:set(verb .. ":" .. location, definition)
            end
        end
        last_updated = os.time()
        cached_spec:set("last-updated", last_updated)
        return service.location
    else
        return cached_spec:get('location')
    end
end


function check_body_size(max_body_size)
    local method = ngx.req.get_method()

    if not method == 'POST' then
        return
    end
    if not max_body_size then
        return
    end

    local sock, err = ngx.req.socket()
    if not sock then
        if err == 'no body' then
            return
        else
            return util.bad_request(err)
        end
    end

    local content_length = tonumber(ngx.req.get_headers()['content-length'])
    local chunk_size = 4096
    if content_length then
        if content_length < chunk_size then
            chunk_size = content_length
        end
    end

    sock:settimeout(0)

    -- reading the request body
    ngx.req.init_body(128 * 1024)
    local size = 0

    while true do
        if content_length then
            if size >= content_length then
                break
            end
        end
        local data, err, partial = sock:receive(chunk_size)
        data = data or partial
        if not data then
            return bad_request("Missing data")
        end


        ngx.req.append_body(data)
        size = size + len(data)

        if size >= max_body_size then
            ngx.exit(413)
        end

        local less = content_length - size
        if less < chunk_size then
            chunk_size = less
        end
    end
    ngx.req.finish_body()
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

    --
    -- checking the query arguments
    --
    local definition = cjson.decode(cached_value)
    local params = definition.parameters or {}
    local limits = definition.limits or {}
    local args = ngx.req.get_uri_args()

    -- let's check if we have all required args first
    local provided_args = util.Keys(args)

    for key, value in pairs(params) do
        if value.required and not provided_args[key] then
            return util.bad_request("Missing " .. key)
        end
    end

    -- now let's validate the args we got
    -- TODO: we should build all those regexps when we read the spec file
    -- and have them loaded in the cache so we don't
    -- do it again
    for key, val in pairs(args) do
        local constraint = params[key]
        if constraint then
            if constraint['validation'] then
                local validation = constraint['validation']
                local t, v = validation:match('(%a+):(.*)')
                if not t then
                    -- not a prefix:
                    t = validation
                    v = ''
                end

                if t == 'regexp' then
                    if not rex.match(val, v) then
                        -- the value does not match the constraints
                        return util.bad_request("Field does not match " .. key)
                    end
                elseif t == 'digits' then
                    local pattern = '[0-9]{' .. v .. '}'
                    if not rex.match(val, pattern) then
                        -- the value does not match the constraints
                        return util.bad_request("Field does not match " .. key)
                    end
                elseif t == 'values' then
                    local pattern = '(' .. v .. ')'
                    if not rex.match(val, pattern) then
                        -- the value does not match the constraints
                        return util.bad_request("Field does not match " .. key)
                    end
                elseif t == 'RFC3339' then
                    if not pcall(function() date(val) end) then
                        return util.bad_request("Field is not RFC3339 " .. key)
                    end
                else
                    -- XXX should be detected at indexing time
                    return util.bad_request("Bad rule " .. t)
                end
            end
    else
        -- this field was not declared
        return util.bad_request("Unknown field " .. key)
    end

    end

    return location, limits, params
end


-- main code
-- TODO make this a lib so we can use it with other
-- filters

-- abort if we don't have any use agent
local key = ngx.var.http_user_agent
if not key then
    return util.bad_request("no user-agent found")
end

-- set the proxy_pass value by matching
-- the request against the api specs
local limits, params
ngx.var.target, limits, params = match()

-- control the body size with the general value or with the
-- limits provided

local max_size = util.size2int(limits.max_body_size) or util.size2int(ngx.var.max_body_size)
check_body_size(max_size)

