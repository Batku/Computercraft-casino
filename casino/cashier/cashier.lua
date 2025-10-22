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
    
    -- Fancy title with spacing
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.orange)
    local title = "C A S H I E R"
    local titleX = math.floor((w - #title) / 2)
    monitor.setCursorPos(titleX, 1)
    monitor.write(title)
    
    -- Decorative border
    ui.drawCenteredText(monitor, 2, "-------------------", colors.black, colors.yellow)
    
    -- Player info
    if username then
        monitor.setCursorPos(2, 4)
        monitor.setTextColor(colors.white)
        monitor.write("Player: ")
        monitor.setTextColor(colors.lime)
        monitor.write(username)
        
        monitor.setCursorPos(2, 5)
        monitor.setTextColor(colors.white)
        monitor.write("Balance: ")
        monitor.setTextColor(colors.lime)
        monitor.write(ui.formatNumber(balance or 0))
    else
        ui.drawCenteredText(monitor, 4, "Insert Player Card", colors.black, colors.orange)
    end
    
    -- Bigger centered buttons
    local btnW = 15
    local btnX = math.floor((w - btnW) / 2)
    
    ui.drawButton(monitor, btnX, 8, btnW, 3, "DEPOSIT", colors.green, colors.white)
    ui.drawButton(monitor, btnX, 12, btnW, 3, "WITHDRAW", colors.blue, colors.white)
    
    if not username then
        ui.drawButton(monitor, btnX, h - 3, btnW, 3, "GET CARD", colors.purple, colors.white)
    else
        ui.drawButton(monitor, btnX, h - 3, btnW, 3, "RETURN CARD", colors.red, colors.white)
    end
end

-- Draw deposit UI
local function drawDepositUI(monitor, availableDiamonds, selectedAmount, balance)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Fancy title
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.orange)
    local title = "D E P O S I T"
    local titleX = math.floor((w - #title) / 2)
    monitor.setCursorPos(titleX, 1)
    monitor.write(title)
    
    ui.drawCenteredText(monitor, 2, "-------------------", colors.black, colors.yellow)
    
    ui.drawCenteredText(monitor, 4, "Available: " .. availableDiamonds, colors.black, colors.white)
    
    -- LARGE selected amount in center
    monitor.setCursorPos(1, 6)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.lime)
    local amtText = tostring(selectedAmount)
    local amtX = math.floor((w - #amtText) / 2)
    monitor.setCursorPos(amtX, 6)
    monitor.write(amtText)
    
    if balance then
        ui.drawCenteredText(monitor, 8, "Balance: " .. ui.formatNumber(balance), colors.black, colors.gray)
    end
    
    -- Amount buttons (bigger and centered)
    local btnW = 7
    local startX = math.floor((w - (btnW * 3 + 2)) / 2)
    
    ui.drawButton(monitor, startX, h - 11, btnW, 2, "+1", colors.green, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, h - 11, btnW, 2, "+10", colors.green, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, h - 11, btnW, 2, "+64", colors.green, colors.white)
    
    ui.drawButton(monitor, startX, h - 8, btnW, 2, "-1", colors.red, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, h - 8, btnW, 2, "-10", colors.red, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, h - 8, btnW, 2, "ALL", colors.orange, colors.white)
    
    -- Action buttons
    local btnW2 = 10
    local spacing = 2
    local totalW = (btnW2 * 2) + spacing
    local startX2 = math.floor((w - totalW) / 2)
    
    ui.drawButton(monitor, startX2, h - 3, btnW2, 3, "CONFIRM", colors.blue, colors.white)
    ui.drawButton(monitor, startX2 + btnW2 + spacing, h - 3, btnW2, 3, "CANCEL", colors.gray, colors.white)
end

-- Draw withdraw UI
local function drawWithdrawUI(monitor, maxWithdraw, selectedAmount, balance)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Fancy title
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.orange)
    local title = "W I T H D R A W"
    local titleX = math.floor((w - #title) / 2)
    monitor.setCursorPos(titleX, 1)
    monitor.write(title)
    
    ui.drawCenteredText(monitor, 2, "-------------------", colors.black, colors.yellow)
    
    ui.drawCenteredText(monitor, 4, "Balance: " .. ui.formatNumber(balance), colors.black, colors.lime)
    ui.drawCenteredText(monitor, 5, "Max: " .. ui.formatNumber(maxWithdraw), colors.black, colors.white)
    
    -- LARGE selected amount in center
    monitor.setCursorPos(1, 7)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.orange)
    local amtText = tostring(selectedAmount)
    local amtX = math.floor((w - #amtText) / 2)
    monitor.setCursorPos(amtX, 7)
    monitor.write(amtText)
    
    -- Amount buttons (bigger and centered)
    local btnW = 7
    local startX = math.floor((w - (btnW * 3 + 2)) / 2)
    
    ui.drawButton(monitor, startX, h - 11, btnW, 2, "+1", colors.green, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, h - 11, btnW, 2, "+10", colors.green, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, h - 11, btnW, 2, "+64", colors.green, colors.white)
    
    ui.drawButton(monitor, startX, h - 8, btnW, 2, "-1", colors.red, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, h - 8, btnW, 2, "-10", colors.red, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, h - 8, btnW, 2, "MAX", colors.orange, colors.white)
    
    -- Action buttons
    local btnW2 = 10
    local spacing = 2
    local totalW = (btnW2 * 2) + spacing
    local startX2 = math.floor((w - totalW) / 2)
    
    ui.drawButton(monitor, startX2, h - 3, btnW2, 3, "CONFIRM", colors.blue, colors.white)
    ui.drawButton(monitor, startX2 + btnW2 + spacing, h - 3, btnW2, 3, "CANCEL", colors.gray, colors.white)
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

-- Check how many diamonds player can receive based on inventory space
local function getMaxWithdrawAmount(inventoryManager, balance)
    local emptySlots = inventoryManager.getEmptySpace()
    local maxByInventory = emptySlots * 64  -- Max 64 diamonds per slot
    return math.min(balance, maxByInventory)
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
        local btnW = 7
        local startX = math.floor((w - (btnW * 3 + 2)) / 2)
        local btnW2 = 10
        local spacing = 2
        local totalW = (btnW2 * 2) + spacing
        local startX2 = math.floor((w - totalW) / 2)
        
        -- Amount adjustment
        if ui.inBounds(x, y, startX, h - 11, btnW, 2) then
            selectedAmount = math.min(selectedAmount + 1, availableDiamonds)
        elseif ui.inBounds(x, y, startX + btnW + 1, h - 11, btnW, 2) then
            selectedAmount = math.min(selectedAmount + 10, availableDiamonds)
        elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, h - 11, btnW, 2) then
            selectedAmount = math.min(selectedAmount + 64, availableDiamonds)
        elseif ui.inBounds(x, y, startX, h - 8, btnW, 2) then
            selectedAmount = math.max(selectedAmount - 1, 1)
        elseif ui.inBounds(x, y, startX + btnW + 1, h - 8, btnW, 2) then
            selectedAmount = math.max(selectedAmount - 10, 1)
        elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, h - 8, btnW, 2) then
            selectedAmount = availableDiamonds
        elseif ui.inBounds(x, y, startX2, h - 3, btnW2, 3) then
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
        elseif ui.inBounds(x, y, startX2 + btnW2 + spacing, h - 3, btnW2, 3) then
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
    
    local maxWithdraw = getMaxWithdrawAmount(inventoryManager, balance)
    
    if maxWithdraw == 0 then
        monitor.setBackgroundColor(colors.black)
        monitor.clear()
        ui.drawCenteredText(monitor, 6, "Inventory full!", colors.black, colors.red)
        ui.drawCenteredText(monitor, 7, "Free up some space", colors.black, colors.red)
        sleep(2)
        return balance
    end
    
    local selectedAmount = math.min(1, maxWithdraw)
    
    while true do
        drawWithdrawUI(monitor, maxWithdraw, selectedAmount, balance)
        
        local event, side, x, y = os.pullEvent("monitor_touch")
        local w, h = monitor.getSize()
        local btnW = 7
        local startX = math.floor((w - (btnW * 3 + 2)) / 2)
        local btnW2 = 10
        local spacing = 2
        local totalW = (btnW2 * 2) + spacing
        local startX2 = math.floor((w - totalW) / 2)
        
        -- Amount adjustment
        if ui.inBounds(x, y, startX, h - 11, btnW, 2) then
            selectedAmount = math.min(selectedAmount + 1, maxWithdraw)
        elseif ui.inBounds(x, y, startX + btnW + 1, h - 11, btnW, 2) then
            selectedAmount = math.min(selectedAmount + 10, maxWithdraw)
        elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, h - 11, btnW, 2) then
            selectedAmount = math.min(selectedAmount + 64, maxWithdraw)
        elseif ui.inBounds(x, y, startX, h - 8, btnW, 2) then
            selectedAmount = math.max(selectedAmount - 1, 1)
        elseif ui.inBounds(x, y, startX + btnW + 1, h - 8, btnW, 2) then
            selectedAmount = math.max(selectedAmount - 10, 1)
        elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, h - 8, btnW, 2) then
            selectedAmount = maxWithdraw
        elseif ui.inBounds(x, y, startX2, h - 3, btnW2, 3) then
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
        elseif ui.inBounds(x, y, startX2 + btnW2 + spacing, h - 3, btnW2, 3) then
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
        local btnW = 15
        local startX = math.floor((w - btnW) / 2)
        
        if currentUsername then
            -- Player card inserted
            if ui.inBounds(x, y, startX, 8, btnW, 3) then
                -- Deposit
                currentBalance = deposit(inventoryManager, monitor, currentUsername, currentBalance)
            elseif ui.inBounds(x, y, startX, 12, btnW, 3) then
                -- Withdraw
                currentBalance = withdraw(inventoryManager, monitor, currentUsername, currentBalance)
            elseif ui.inBounds(x, y, startX, h - 3, btnW, 3) then
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
            if ui.inBounds(x, y, startX, 8, btnW, 3) or ui.inBounds(x, y, startX, 12, btnW, 3) then
                -- Tried to deposit/withdraw without card
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                ui.drawCenteredText(monitor, 6, "Please insert", colors.black, colors.red)
                ui.drawCenteredText(monitor, 7, "player card first!", colors.black, colors.red)
                sleep(2)
            elseif ui.inBounds(x, y, startX, h - 3, btnW, 3) then
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
