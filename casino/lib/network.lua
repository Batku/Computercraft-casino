-- Network Protocol Library for Casino System
-- Handles communication between game machines and central server

local PROTOCOL = "casino_network"
local TIMEOUT = 5

local network = {}

-- Initialize network (opens modem on wired network)
function network.init()
    local modem = peripheral.find("modem")
    if not modem then
        error("No modem found!")
    end
    
    if not modem.isWireless() then
        rednet.open(peripheral.getName(modem))
    else
        error("Wireless modem detected - need wired modem!")
    end
    
    return modem
end

-- Send request to server and wait for response
function network.request(requestType, data)
    local message = {
        type = requestType,
        data = data,
        timestamp = os.epoch("utc")
    }
    
    rednet.broadcast(message, PROTOCOL)
    
    -- Wait for response
    local timer = os.startTimer(TIMEOUT)
    while true do
        local event, param1, param2, param3 = os.pullEvent()
        
        if event == "rednet_message" and param3 == PROTOCOL then
            local response = param2
            if response.replyTo == requestType then
                os.cancelTimer(timer)
                return response.success, response.data, response.error
            end
        elseif event == "timer" and param1 == timer then
            return false, nil, "Request timeout"
        end
    end
end

-- Server: Listen for requests and handle them
function network.listen(handler)
    while true do
        local senderId, message, protocol = rednet.receive(PROTOCOL)
        
        if type(message) == "table" and message.type then
            local success, data, error = handler(message.type, message.data, senderId)
            
            local response = {
                replyTo = message.type,
                success = success,
                data = data,
                error = error
            }
            
            rednet.send(senderId, response, PROTOCOL)
        end
    end
end

return network
