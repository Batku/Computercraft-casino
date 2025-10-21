-- Casino Cashier System
-- Handles deposits, withdrawals, and player card creation

local network = require("/casino/lib/network")
local ui = require("/casino/lib/ui")

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

-- Draw main menu
local function drawMainMenu(monitor, username, balance)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Title
    ui.drawCenteredText(monitor, 1, "CASINO CASHIER", colors.black, colors.yellow)
    
    -- Player info
    if username then
        ui.drawCenteredText(monitor, 3, "Player: " .. username, colors.black, colors.white)
        ui.drawCenteredText(monitor, 4, "Balance: " .. ui.formatNumber(balance or 0), colors.black, colors.lime)
    else
        ui.drawCenteredText(monitor, 3, "Insert Player Card", colors.black, colors.orange)
    end
    
    -- Buttons
    ui.drawButton(monitor, 3, 6, 19, 2, "DEPOSIT", colors.green, colors.white)
    ui.drawButton(monitor, 3, 9, 19, 2, "WITHDRAW", colors.blue, colors.white)
    
    if not username then
        ui.drawButton(monitor, 3, h - 2, 19, 2, "GET CARD", colors.purple, colors.white)
    else
        ui.drawButton(monitor, 3, h - 2, 19, 2, "RETURN CARD", colors.red, colors.white)
    end
end

-- Draw deposit UI
local function drawDepositUI(monitor, availableDiamonds, selectedAmount, balance)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    ui.drawCenteredText(monitor, 1, "DEPOSIT DIAMONDS", colors.black, colors.yellow)
    
    ui.drawCenteredText(monitor, 3, "Available: " .. availableDiamonds, colors.black, colors.white)
    ui.drawCenteredText(monitor, 4, "Selected: " .. selectedAmount, colors.black, colors.lime)
    
    if balance then
        ui.drawCenteredText(monitor, 5, "Balance: " .. ui.formatNumber(balance), colors.black, colors.gray)
    end
    
    -- Amount buttons
    ui.drawButton(monitor, 2, 7, 6, 1, "+1", colors.green, colors.white)
    ui.drawButton(monitor, 9, 7, 6, 1, "+10", colors.green, colors.white)
    ui.drawButton(monitor, 16, 7, 6, 1, "+64", colors.green, colors.white)
    
    ui.drawButton(monitor, 2, 9, 6, 1, "-1", colors.red, colors.white)
    ui.drawButton(monitor, 9, 9, 6, 1, "-10", colors.red, colors.white)
    ui.drawButton(monitor, 16, 9, 6, 1, "ALL", colors.orange, colors.white)
    
    -- Action buttons
    ui.drawButton(monitor, 3, h - 3, 8, 2, "CONFIRM", colors.blue, colors.white)
    ui.drawButton(monitor, 13, h - 3, 8, 2, "CANCEL", colors.gray, colors.white)
end

-- Draw withdraw UI
local function drawWithdrawUI(monitor, maxWithdraw, selectedAmount, balance)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    ui.drawCenteredText(monitor, 1, "WITHDRAW CREDITS", colors.black, colors.yellow)
    
    ui.drawCenteredText(monitor, 3, "Balance: " .. ui.formatNumber(balance), colors.black, colors.lime)
    ui.drawCenteredText(monitor, 4, "Max: " .. ui.formatNumber(maxWithdraw), colors.black, colors.white)
    ui.drawCenteredText(monitor, 5, "Selected: " .. selectedAmount, colors.black, colors.orange)
    
    -- Amount buttons
    ui.drawButton(monitor, 2, 7, 6, 1, "+1", colors.green, colors.white)
    ui.drawButton(monitor, 9, 7, 6, 1, "+10", colors.green, colors.white)
    ui.drawButton(monitor, 16, 7, 6, 1, "+64", colors.green, colors.white)
    
    ui.drawButton(monitor, 2, 9, 6, 1, "-1", colors.red, colors.white)
    ui.drawButton(monitor, 9, 9, 6, 1, "-10", colors.red, colors.white)
    ui.drawButton(monitor, 16, 9, 6, 1, "MAX", colors.orange, colors.white)
    
    -- Action buttons
    ui.drawButton(monitor, 3, h - 3, 8, 2, "CONFIRM", colors.blue, colors.white)
    ui.drawButton(monitor, 13, h - 3, 8, 2, "CANCEL", colors.gray, colors.white)
end

-- Get player username
local function getPlayerUsername(inventoryManager)
    local owner = inventoryManager.getOwner()
    return owner
end

-- Count diamonds in player inventory
local function countPlayerDiamonds(inventoryManager)
    local items = inventoryManager.getItems()
    local diamondCount = 0
    local diamondSlots = {}
    
    for _, item in ipairs(items) do
        if item.name == "minecraft:diamond" then
            diamondCount = diamondCount + item.count
            table.insert(diamondSlots, {slot = item.slot, count = item.count})
        end
    end
    
    return diamondCount, diamondSlots
end

-- Count diamonds in chest
local function countChestDiamonds(inventoryManager)
    local list = inventoryManager.list()
    local availableDiamonds = 0
    
    for slot, item in pairs(list) do
        if item.name == "minecraft:diamond" then
            availableDiamonds = availableDiamonds + item.count
        end
    end
    
    return availableDiamonds
end

-- Deposit diamonds
local function deposit(inventoryManager, monitor, username, balance)
    local availableDiamonds, diamondSlots = countPlayerDiamonds(inventoryManager)
    
    if availableDiamonds == 0 then
        monitor.setBackgroundColor(colors.black)
        monitor.clear()
        ui.drawCenteredText(monitor, 6, "No diamonds in inventory!", colors.black, colors.red)
        sleep(2)
        return balance
    end
    
    local selectedAmount = math.min(1, availableDiamonds)
    
    while true do
        drawDepositUI(monitor, availableDiamonds, selectedAmount, balance)
        
        local event, side, x, y = os.pullEvent("monitor_touch")
        local w, h = monitor.getSize()
        
        -- Amount adjustment
        if ui.inBounds(x, y, 2, 7, 6, 1) then
            selectedAmount = math.min(selectedAmount + 1, availableDiamonds)
        elseif ui.inBounds(x, y, 9, 7, 6, 1) then
            selectedAmount = math.min(selectedAmount + 10, availableDiamonds)
        elseif ui.inBounds(x, y, 16, 7, 6, 1) then
            selectedAmount = math.min(selectedAmount + 64, availableDiamonds)
        elseif ui.inBounds(x, y, 2, 9, 6, 1) then
            selectedAmount = math.max(selectedAmount - 1, 1)
        elseif ui.inBounds(x, y, 9, 9, 6, 1) then
            selectedAmount = math.max(selectedAmount - 10, 1)
        elseif ui.inBounds(x, y, 16, 9, 6, 1) then
            selectedAmount = availableDiamonds
        elseif ui.inBounds(x, y, 3, h - 3, 8, 2) then
            -- Confirm
            local removed = 0
            local remaining = selectedAmount
            
            for _, slot in ipairs(diamondSlots) do
                if remaining <= 0 then break end
                
                local toRemove = math.min(remaining, slot.count)
                local count = inventoryManager.removeItemFromPlayer("back", {
                    name = "minecraft:diamond",
                    fromSlot = slot.slot,
                    count = toRemove
                })
                removed = removed + count
                remaining = remaining - count
            end
            
            if removed > 0 then
                local success, data = network.request("add_balance", {
                    username = username,
                    amount = removed
                })
                
                if success then
                    balance = data.balance
                    monitor.setBackgroundColor(colors.black)
                    monitor.clear()
                    ui.drawCenteredText(monitor, 5, "Deposited!", colors.black, colors.lime)
                    ui.drawCenteredText(monitor, 6, "+" .. ui.formatNumber(removed) .. " credits", colors.black, colors.white)
                    ui.drawCenteredText(monitor, 7, "Balance: " .. ui.formatNumber(balance), colors.black, colors.yellow)
                    sleep(2)
                end
            end
            
            return balance
        elseif ui.inBounds(x, y, 13, h - 3, 8, 2) then
            -- Cancel
            return balance
        end
    end
end

-- Withdraw credits
local function withdraw(inventoryManager, monitor, username, balance)
    if balance == 0 then
        monitor.setBackgroundColor(colors.black)
        monitor.clear()
        ui.drawCenteredText(monitor, 6, "No credits to withdraw!", colors.black, colors.red)
        sleep(2)
        return balance
    end
    
    local availableDiamonds = countChestDiamonds(inventoryManager)
    local maxWithdraw = math.min(balance, availableDiamonds)
    
    if maxWithdraw == 0 then
        monitor.setBackgroundColor(colors.black)
        monitor.clear()
        ui.drawCenteredText(monitor, 6, "No diamonds available!", colors.black, colors.red)
        ui.drawCenteredText(monitor, 7, "in cashier chest", colors.black, colors.red)
        sleep(2)
        return balance
    end
    
    local selectedAmount = math.min(1, maxWithdraw)
    
    while true do
        drawWithdrawUI(monitor, maxWithdraw, selectedAmount, balance)
        
        local event, side, x, y = os.pullEvent("monitor_touch")
        local w, h = monitor.getSize()
        
        -- Amount adjustment
        if ui.inBounds(x, y, 2, 7, 6, 1) then
            selectedAmount = math.min(selectedAmount + 1, maxWithdraw)
        elseif ui.inBounds(x, y, 9, 7, 6, 1) then
            selectedAmount = math.min(selectedAmount + 10, maxWithdraw)
        elseif ui.inBounds(x, y, 16, 7, 6, 1) then
            selectedAmount = math.min(selectedAmount + 64, maxWithdraw)
        elseif ui.inBounds(x, y, 2, 9, 6, 1) then
            selectedAmount = math.max(selectedAmount - 1, 1)
        elseif ui.inBounds(x, y, 9, 9, 6, 1) then
            selectedAmount = math.max(selectedAmount - 10, 1)
        elseif ui.inBounds(x, y, 16, 9, 6, 1) then
            selectedAmount = maxWithdraw
        elseif ui.inBounds(x, y, 3, h - 3, 8, 2) then
            -- Confirm
            local added = inventoryManager.addItemToPlayer("back", {
                name = "minecraft:diamond",
                count = selectedAmount
            })
            
            if added > 0 then
                local success, data = network.request("subtract_balance", {
                    username = username,
                    amount = added
                })
                
                if success then
                    balance = data.balance
                    monitor.setBackgroundColor(colors.black)
                    monitor.clear()
                    ui.drawCenteredText(monitor, 5, "Withdrew!", colors.black, colors.lime)
                    ui.drawCenteredText(monitor, 6, added .. " diamonds", colors.black, colors.white)
                    ui.drawCenteredText(monitor, 7, "Balance: " .. ui.formatNumber(balance), colors.black, colors.yellow)
                    sleep(2)
                end
            else
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                ui.drawCenteredText(monitor, 6, "Inventory full!", colors.black, colors.red)
                sleep(2)
            end
            
            return balance
        elseif ui.inBounds(x, y, 13, h - 3, 8, 2) then
            -- Cancel
            return balance
        end
    end
end

-- Main loop
local function main()
    print("Cashier System Starting...")
    
    network.init()
    print("Network initialized")
    
    local monitor, inventoryManager, playerDetector = initPeripherals()
    print("Peripherals initialized")
    
    local currentUsername = nil
    local currentBalance = 0
    
    while true do
        -- Check for player card
        currentUsername = getPlayerUsername(inventoryManager)
        
        if currentUsername then
            -- Get balance
            local success, data = network.request("get_balance", {username = currentUsername})
            if success then
                currentBalance = data.balance
            end
        end
        
        drawMainMenu(monitor, currentUsername, currentBalance)
        
        local event, side, x, y = os.pullEvent("monitor_touch")
        local w, h = monitor.getSize()
        
        if currentUsername then
            -- Player card inserted
            if ui.inBounds(x, y, 3, 6, 19, 2) then
                -- Deposit
                currentBalance = deposit(inventoryManager, monitor, currentUsername, currentBalance)
            elseif ui.inBounds(x, y, 3, 9, 19, 2) then
                -- Withdraw
                currentBalance = withdraw(inventoryManager, monitor, currentUsername, currentBalance)
            elseif ui.inBounds(x, y, 3, h - 2, 19, 2) then
                -- Return card
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                ui.drawCenteredText(monitor, 5, "Returning card...", colors.black, colors.yellow)
                ui.drawCenteredText(monitor, 7, "Final Balance:", colors.black, colors.white)
                ui.drawCenteredText(monitor, 8, ui.formatNumber(currentBalance) .. " credits", colors.black, colors.lime)
                
                redstone.setOutput("back", true)
                sleep(0.5)
                redstone.setOutput("back", false)
                
                sleep(2)
                currentUsername = nil
                currentBalance = 0
            end
        else
            -- No card inserted
            if ui.inBounds(x, y, 3, 6, 19, 2) or ui.inBounds(x, y, 3, 9, 19, 2) then
                -- Tried to deposit/withdraw without card
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                ui.drawCenteredText(monitor, 6, "Please insert", colors.black, colors.red)
                ui.drawCenteredText(monitor, 7, "player card first!", colors.black, colors.red)
                sleep(2)
            elseif ui.inBounds(x, y, 3, h - 2, 19, 2) then
                -- Get new player card
                local players = playerDetector.getPlayersInRange(5)
                if #players > 0 then
                    local username = players[1]
                    
                    -- Create account if doesn't exist
                    network.request("create_account", {username = username})
                    
                    -- Give player card (assuming you have a dispenser)
                    monitor.setBackgroundColor(colors.black)
                    monitor.clear()
                    ui.drawCenteredText(monitor, 5, "Creating card for", colors.black, colors.yellow)
                    ui.drawCenteredText(monitor, 6, username, colors.black, colors.white)
                    
                    redstone.setOutput("right", true)
                    sleep(0.5)
                    redstone.setOutput("right", false)
                    
                    sleep(2)
                else
                    monitor.setBackgroundColor(colors.black)
                    monitor.clear()
                    ui.drawCenteredText(monitor, 6, "No player detected!", colors.black, colors.red)
                    ui.drawCenteredText(monitor, 7, "Stand closer (5 blocks)", colors.black, colors.orange)
                    sleep(2)
                end
            end
        end
    end
end

main()
