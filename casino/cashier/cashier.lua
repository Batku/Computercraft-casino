-- Casino Cashier System
-- Handles deposits, withdrawals, and player card creation

local network = require("/casino/lib/network")

-- Find peripherals
local function initPeripherals()
    local monitor = peripheral.find("monitor")
    if not monitor then
        error("No monitor found!")
    end
    monitor.setTextScale(0.5)
    
    local inventoryManager = peripheral.find("inventory_manager")
    if not inventoryManager then
        error("No inventory manager found!")
    end
    
    local playerDetector = peripheral.find("player_detector")
    if not playerDetector then
        error("No player detector found!")
    end
    
    return monitor, inventoryManager, playerDetector
end

-- Draw UI
local function drawUI(monitor, message, balance)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Title
    monitor.setCursorPos(math.floor((w - 13) / 2) + 1, 2)
    monitor.setTextColor(colors.yellow)
    monitor.write("CASINO CASHIER")
    
    -- Instructions
    monitor.setCursorPos(2, 4)
    monitor.setTextColor(colors.white)
    monitor.write("1. Deposit Diamonds")
    
    monitor.setCursorPos(2, 5)
    monitor.write("2. Withdraw Credits")
    
    monitor.setCursorPos(2, 6)
    monitor.write("3. Get Player Card")
    
    monitor.setCursorPos(2, 7)
    monitor.write("4. Return Player Card")
    
    -- Balance display
    if balance then
        monitor.setCursorPos(2, 9)
        monitor.setTextColor(colors.lime)
        monitor.write("Balance: " .. balance .. " credits")
    end
    
    -- Message
    if message then
        monitor.setCursorPos(2, h - 1)
        monitor.setTextColor(colors.orange)
        monitor.write(message)
    end
end

-- Create player card
local function createPlayerCard(inventoryManager, username)
    -- The player detector can create memory cards
    -- We'll use the inventory manager to give it to them
    local success = inventoryManager.addItemToPlayer("down", {
        name = "advancedperipherals:memory_card",
        count = 1
    })
    
    return success > 0
end

-- Get player username
local function getPlayerUsername(inventoryManager)
    local owner = inventoryManager.getOwner()
    return owner
end

-- Deposit diamonds
local function deposit(inventoryManager, monitor)
    local username = getPlayerUsername(inventoryManager)
    if not username then
        drawUI(monitor, "Please insert player card first!", nil)
        return
    end
    
    -- Count diamonds in player inventory
    local items = inventoryManager.getItems()
    local diamondCount = 0
    local diamondSlots = {}
    
    for _, item in ipairs(items) do
        if item.name == "minecraft:diamond" then
            diamondCount = diamondCount + item.count
            table.insert(diamondSlots, {slot = item.slot, count = item.count})
        end
    end
    
    if diamondCount == 0 then
        drawUI(monitor, "No diamonds in inventory!", nil)
        return
    end
    
    -- Remove diamonds from player
    local removed = 0
    for _, slot in ipairs(diamondSlots) do
        local count = inventoryManager.removeItemFromPlayer("up", {
            name = "minecraft:diamond",
            fromSlot = slot.slot,
            count = slot.count
        })
        removed = removed + count
    end
    
    -- Add credits to account
    local success, data = network.request("add_balance", {
        username = username,
        amount = removed
    })
    
    if success then
        drawUI(monitor, "Deposited " .. removed .. " diamonds!", data.balance)
    else
        drawUI(monitor, "Error depositing diamonds!", nil)
    end
end

-- Withdraw credits
local function withdraw(inventoryManager, monitor)
    local username = getPlayerUsername(inventoryManager)
    if not username then
        drawUI(monitor, "Please insert player card first!", nil)
        return
    end
    
    -- Get current balance
    local success, data = network.request("get_balance", {username = username})
    if not success then
        drawUI(monitor, "Error getting balance!", nil)
        return
    end
    
    local balance = data.balance
    if balance == 0 then
        drawUI(monitor, "No credits to withdraw!", balance)
        return
    end
    
    -- Check how many diamonds are available in chest
    local list = inventoryManager.list()
    local availableDiamonds = 0
    
    for slot, item in pairs(list) do
        if item.name == "minecraft:diamond" then
            availableDiamonds = availableDiamonds + item.count
        end
    end
    
    local withdrawAmount = math.min(balance, availableDiamonds)
    
    if withdrawAmount == 0 then
        drawUI(monitor, "No diamonds available in cashier!", balance)
        return
    end
    
    -- Add diamonds to player
    local added = inventoryManager.addItemToPlayer("up", {
        name = "minecraft:diamond",
        count = withdrawAmount
    })
    
    if added > 0 then
        -- Subtract credits
        success, data = network.request("subtract_balance", {
            username = username,
            amount = added
        })
        
        if success then
            drawUI(monitor, "Withdrew " .. added .. " diamonds!", data.balance)
        else
            drawUI(monitor, "Error withdrawing!", balance)
        end
    else
        drawUI(monitor, "Inventory full or error!", balance)
    end
end

-- Main loop
local function main()
    print("Cashier System Starting...")
    
    network.init()
    print("Network initialized")
    
    local monitor, inventoryManager, playerDetector = initPeripherals()
    print("Peripherals initialized")
    
    drawUI(monitor, "Ready! Insert player card or select option", nil)
    
    while true do
        local event, side, x, y = os.pullEvent()
        
        if event == "monitor_touch" then
            -- Check which button was pressed
            if y == 4 then
                -- Deposit
                deposit(inventoryManager, monitor)
            elseif y == 5 then
                -- Withdraw
                withdraw(inventoryManager, monitor)
            elseif y == 6 then
                -- Get player card
                -- First check if player is near
                local players = playerDetector.getPlayersInRange(5)
                if #players > 0 then
                    local username = players[1]
                    
                    -- Create account if doesn't exist
                    network.request("create_account", {username = username})
                    
                    -- Give player card
                    redstone.setOutput("right", true)
                    sleep(0.5)
                    redstone.setOutput("right", false)
                    
                    drawUI(monitor, "Player card issued to " .. username, nil)
                else
                    drawUI(monitor, "No player detected nearby!", nil)
                end
            elseif y == 7 then
                -- Return player card
                local username = getPlayerUsername(inventoryManager)
                if username then
                    -- Get final balance
                    local success, data = network.request("get_balance", {username = username})
                    local balance = success and data.balance or 0
                    
                    -- Return card
                    redstone.setOutput("back", true)
                    sleep(0.5)
                    redstone.setOutput("back", false)
                    
                    drawUI(monitor, "Card returned! Balance: " .. balance, nil)
                else
                    drawUI(monitor, "No player card detected!", nil)
                end
            end
        end
    end
end

main()
