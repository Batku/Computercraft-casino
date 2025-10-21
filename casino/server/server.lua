-- Central Casino Server
-- Manages player accounts on floppy disk

local network = require("/casino/lib/network")

local DISK_MOUNT = "/disk"
local DATA_FILE = "/disk/players.json"

-- Initialize disk drive
local function initDisk()
    local drive = peripheral.find("drive")
    if not drive then
        error("No disk drive found!")
    end
    
    if not drive.isDiskPresent() then
        error("No disk in drive!")
    end
    
    return drive
end

-- Load player data from disk
local function loadData()
    if not fs.exists(DATA_FILE) then
        return {}
    end
    
    local file = fs.open(DATA_FILE, "r")
    local content = file.readAll()
    file.close()
    
    if content == "" then
        return {}
    end
    
    return textutils.unserializeJSON(content) or {}
end

-- Save player data to disk
local function saveData(data)
    local file = fs.open(DATA_FILE, "w")
    file.write(textutils.serializeJSON(data))
    file.close()
end

-- Handle incoming requests
local function handleRequest(requestType, data, senderId)
    local players = loadData()
    
    if requestType == "get_balance" then
        local username = data.username
        if not username then
            return false, nil, "No username provided"
        end
        
        local balance = players[username] or 0
        return true, {balance = balance}
        
    elseif requestType == "set_balance" then
        local username = data.username
        local balance = data.balance
        
        if not username then
            return false, nil, "No username provided"
        end
        
        if not balance or balance < 0 then
            return false, nil, "Invalid balance"
        end
        
        players[username] = math.floor(balance)
        saveData(players)
        
        return true, {balance = players[username]}
        
    elseif requestType == "add_balance" then
        local username = data.username
        local amount = data.amount
        
        if not username then
            return false, nil, "No username provided"
        end
        
        if not amount then
            return false, nil, "No amount provided"
        end
        
        players[username] = (players[username] or 0) + math.floor(amount)
        saveData(players)
        
        return true, {balance = players[username]}
        
    elseif requestType == "subtract_balance" then
        local username = data.username
        local amount = data.amount
        
        if not username then
            return false, nil, "No username provided"
        end
        
        if not amount then
            return false, nil, "No amount provided"
        end
        
        local currentBalance = players[username] or 0
        if currentBalance < amount then
            return false, nil, "Insufficient balance"
        end
        
        players[username] = currentBalance - math.floor(amount)
        saveData(players)
        
        return true, {balance = players[username]}
        
    elseif requestType == "create_account" then
        local username = data.username
        
        if not username then
            return false, nil, "No username provided"
        end
        
        if not players[username] then
            players[username] = 0
            saveData(players)
        end
        
        return true, {balance = players[username]}
        
    else
        return false, nil, "Unknown request type"
    end
end

-- Main server loop
local function main()
    print("Casino Server Starting...")
    
    local drive = initDisk()
    print("Disk drive found")
    
    network.init()
    print("Network initialized")
    
    -- Initialize data file if it doesn't exist
    if not fs.exists(DATA_FILE) then
        saveData({})
    end
    
    print("Server ready!")
    print("Listening for requests...")
    
    network.listen(handleRequest)
end

main()
