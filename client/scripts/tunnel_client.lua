local client = require "resty.websocket.client"
local http = require "resty.http"

local ws = client:new()
local ok, err = ws:connect("ws://172.17.0.1:8081/ws")
if not ok then
    ngx.log(ngx.ERR, "Failed to connect: ", err)
    return
end

ws:send_text("my.domain.dev")

while true do
    local msg, _, err = ws:recv_frame()
    if not msg then break end  -- Exit on error

    -- Forward request to local server
    local httpc = http.new()
    local res, err = httpc:request_uri("http://172.17.0.1:4321" .. msg)

    if res then
        ws:send_text(res.body)
    else
        ws:send_text("500 Internal Server Error")
    end
end

ws:send_close()
