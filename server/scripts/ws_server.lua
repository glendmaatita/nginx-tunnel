local server = require "resty.websocket.server"
local dict = ngx.shared.tunnels

-- accept ws connection
local wb, err = server:new{ timeout = 5000, max_payload_len = 65535 }
if not wb then
    ngx.log(ngx.ERR, "WebSocket error: ", err)
    return ngx.exit(444)
end

-- read initial message from client for subdomain
local data, _, err = wb:recv_frame()
if not data then
    ngx.log(ngx.ERR, "Failed to read from WebSocket: ", err)
    return ngx.exit(444)
end

ngx.log(ngx.INFO, "Client registered: ", data)
dict:set(data, wb)  -- Store connection

-- keep connection open
while true do
    local msg, _, err = wb:recv_frame()
    if not msg then break end  -- Exit if client disconnects
end

-- close ws
dict:delete(data)
wb:send_close()
