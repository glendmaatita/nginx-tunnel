local dict = ngx.shared.tunnels
local host = ngx.var.host
local wb = dict:get(host)

if not wb then
    ngx.status = 404
    ngx.say("Tunnel not found")
    return
end

-- request to ws client
local payload = ngx.req.get_method() .. " " .. ngx.var.request_uri
wb:send_text(payload)

-- get response
local msg, _, err = wb:recv_frame()
if not msg then
    ngx.status = 500
    ngx.say("Failed to get response")
    return
end

ngx.say(msg)
