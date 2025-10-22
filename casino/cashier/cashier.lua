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
    if username then
        -- Player has card inserted - normal view at scale 0.5
        monitor.setTextScale(0.5)
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
        ui.drawCenteredText(monitor, 3, "Player: " .. username, colors.black, colors.lime)
        ui.drawCenteredText(monitor, 4, "Balance: " .. ui.formatNumber(balance or 0), colors.black, colors.yellow)
        
        -- Bigger centered buttons
        local btnW = 17
        local btnX = math.floor((w - btnW) / 2)
        
        ui.drawButton(monitor, btnX, 6, btnW, 3, "DEPOSIT", colors.green, colors.white)
        ui.drawButton(monitor, btnX, 10, btnW, 3, "WITHDRAW", colors.blue, colors.white)
        ui.drawButton(monitor, btnX, h - 5, btnW, 3, "RETURN CARD", colors.red, colors.white)
    else
        -- No card - bigger text idle screen at scale 2
        monitor.setTextScale(2)
        monitor.setBackgroundColor(colors.black)
        monitor.clear()
        
        local w, h = monitor.getSize()
        
        monitor.setTextColor(colors.orange)
        local title = "CASHIER"
        local titleX = math.floor((w - #title) / 2) + 1
        monitor.setCursorPos(titleX, 2)
        monitor.write(title)
        
        monitor.setTextColor(colors.yellow)
        local subtitle = "Insert Card"
        local subX = math.floor((w - #subtitle) / 2) + 1
        monitor.setCursorPos(subX, 4)
        monitor.write(subtitle)
        
        -- Button also at scale 2
        local btnW = 10
        local btnX = math.floor((w - btnW) / 2) + 1
        ui.drawButton(monitor, btnX, h - 2, btnW, 2, "GET CARD", colors.purple, colors.white)
    end
end

-- Draw deposit UI
local function drawDepositUI(monitor, availableDiamonds, selectedAmount, balance)
    monitor.setTextScale(0.5)
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
    
    ui.drawCenteredText(monitor, 3, "Available: " .. availableDiamonds, colors.black, colors.white)
    
    -- LARGE selected amount in center
    monitor.setCursorPos(1, 4)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.lime)
    local amtText = tostring(selectedAmount)
    local amtX = math.floor((w - #amtText) / 2)
    monitor.setCursorPos(amtX, 4)
    monitor.write(amtText)
    
    if balance then
        ui.drawCenteredText(monitor, 5, "Balance: " .. ui.formatNumber(balance), colors.black, colors.gray)
    end
    
    -- Amount buttons (bigger and centered)
    local btnW = 7
    local startX = math.floor((w - (btnW * 3 + 2)) / 2)
    
    ui.drawButton(monitor, startX, 6, btnW, 3, "+1", colors.green, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, 6, btnW, 3, "+10", colors.green, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, 6, btnW, 3, "+64", colors.green, colors.white)
    
    ui.drawButton(monitor, startX, 10, btnW, 3, "-1", colors.red, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, 10, btnW, 3, "-10", colors.red, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, 10, btnW, 3, "ALL", colors.orange, colors.white)
    
    -- Action buttons
    local btnW2 = 10
    local spacing = 2
    local totalW = (btnW2 * 2) + spacing
    local startX2 = math.floor((w - totalW) / 2)
    
    ui.drawButton(monitor, startX2, h - 5, btnW2, 3, "CONFIRM", colors.blue, colors.white)
    ui.drawButton(monitor, startX2 + btnW2 + spacing, h - 5, btnW2, 3, "CANCEL", colors.gray, colors.white)
end

-- Draw withdraw UI
local function drawWithdrawUI(monitor, maxWithdraw, selectedAmount, balance)
    monitor.setTextScale(0.5)
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
    
    -- LARGE selected amount in center
    monitor.setCursorPos(1, 4)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.orange)
    local amtText = tostring(selectedAmount)
    local amtX = math.floor((w - #amtText) / 2)
    monitor.setCursorPos(amtX, 4)
    monitor.write(amtText)
    
    -- Amount buttons (bigger and centered)
    local btnW = 7
    local startX = math.floor((w - (btnW * 3 + 2)) / 2)
    
    ui.drawButton(monitor, startX, 6, btnW, 3, "+1", colors.green, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, 6, btnW, 3, "+10", colors.green, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, 6, btnW, 3, "+64", colors.green, colors.white)
    
    ui.drawButton(monitor, startX, 10, btnW, 3, "-1", colors.red, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, 10, btnW, 3, "-10", colors.red, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, 10, btnW, 3, "MAX", colors.orange, colors.white)
    
    -- Balance and max info below buttons
    ui.drawCenteredText(monitor, h - 8, "Balance: " .. ui.formatNumber(balance), colors.black, colors.lime)
    ui.drawCenteredText(monitor, h - 7, "Max: " .. ui.formatNumber(maxWithdraw), colors.black, colors.white)
    
    -- Action buttons
    local btnW2 = 10
    local spacing = 2
    local totalW = (btnW2 * 2) + spacing
    local startX2 = math.floor((w - totalW) / 2)
    
    ui.drawButton(monitor, startX2, h - 5, btnW2, 3, "CONFIRM", colors.blue, colors.white)
    ui.drawButton(monitor, startX2 + btnW2 + spacing, h - 5, btnW2, 3, "CANCEL", colors.gray, colors.white)
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
        if ui.inBounds(x, y, startX, 6, btnW, 3) then
            selectedAmount = math.min(selectedAmount + 1, availableDiamonds)
        elseif ui.inBounds(x, y, startX + btnW + 1, 6, btnW, 3) then
            selectedAmount = math.min(selectedAmount + 10, availableDiamonds)
        elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, 6, btnW, 3) then
            selectedAmount = math.min(selectedAmount + 64, availableDiamonds)
        elseif ui.inBounds(x, y, startX, 10, btnW, 3) then
            selectedAmount = math.max(selectedAmount - 1, 1)
        elseif ui.inBounds(x, y, startX + btnW + 1, 10, btnW, 3) then
            selectedAmount = math.max(selectedAmount - 10, 1)
        elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, 10, btnW, 3) then
            selectedAmount = availableDiamonds
        elseif ui.inBounds(x, y, startX2, h - 5, btnW2, 3) then
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
        elseif ui.inBounds(x, y, startX2 + btnW2 + spacing, h - 5, btnW2, 3) then
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
        if ui.inBounds(x, y, startX, 6, btnW, 3) then
            selectedAmount = math.min(selectedAmount + 1, maxWithdraw)
        elseif ui.inBounds(x, y, startX + btnW + 1, 6, btnW, 3) then
            selectedAmount = math.min(selectedAmount + 10, maxWithdraw)
        elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, 6, btnW, 3) then
            selectedAmount = math.min(selectedAmount + 64, maxWithdraw)
        elseif ui.inBounds(x, y, startX, 10, btnW, 3) then
            selectedAmount = math.max(selectedAmount - 1, 1)
        elseif ui.inBounds(x, y, startX + btnW + 1, 10, btnW, 3) then
            selectedAmount = math.max(selectedAmount - 10, 1)
        elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, 10, btnW, 3) then
            selectedAmount = maxWithdraw
        elseif ui.inBounds(x, y, startX2, h - 5, btnW2, 3) then
            -- Confirm
            local totalAdded = 0
            local amountToAdd = selectedAmount
            
            -- Add diamonds in batches of 64 (max stack size)
            while amountToAdd > 0 do
                local batchSize = math.min(64, amountToAdd)
                local added = inventoryManager.addItemToPlayer("back", {
                    name = "minecraft:diamond",
                    count = batchSize
                })
                
                if added > 0 then
                    totalAdded = totalAdded + added
                    amountToAdd = amountToAdd - added
                    
                    -- If we couldn't add the full batch, inventory is full
                    if added < batchSize then
                        break
                    end
                else
                    -- Can't add any more
                    break
                end
            end
            
            if totalAdded > 0 then
                local success, data = network.request("subtract_balance", {
                    username = username,
                    amount = totalAdded
                })
                
                if success then
                    balance = data.balance
                    monitor.setBackgroundColor(colors.black)
                    monitor.clear()
                    ui.drawCenteredText(monitor, 5, "Withdrew!", colors.black, colors.lime)
                    ui.drawCenteredText(monitor, 6, totalAdded .. " diamonds", colors.black, colors.white)
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
        elseif ui.inBounds(x, y, startX2 + btnW2 + spacing, h - 5, btnW2, 3) then
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
        
        local x, y  -- Declare here so it's accessible throughout the loop
        
        if currentUsername then
            -- Get balance
            local success, data = network.request("get_balance", {username = currentUsername})
            if success then
                currentBalance = data.balance
            end
            
            drawMainMenu(monitor, currentUsername, currentBalance)
            
            -- Make sure we're at the right scale for click detection
            monitor.setTextScale(0.5)
            
            local event, side
            event, side, x, y = os.pullEvent("monitor_touch")
        else
            -- No card - animate with rainbow effect
            local rainbowColors = {colors.red, colors.orange, colors.yellow, colors.lime, colors.cyan, colors.lightBlue, colors.blue, colors.purple, colors.magenta, colors.pink}
            local colorIndex = 1
            
            while true do
                currentUsername = getPlayerUsername(inventoryManager)
                if currentUsername then break end
                
                -- Draw with current rainbow color
                monitor.setTextScale(2)
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                
                local w, h = monitor.getSize()
                
                monitor.setTextColor(rainbowColors[colorIndex])
                local title = "CASHIER"
                local titleX = math.floor((w - #title) / 2) + 1
                monitor.setCursorPos(titleX, 2)
                monitor.write(title)
                
                colorIndex = (colorIndex % #rainbowColors) + 1
                monitor.setTextColor(rainbowColors[colorIndex])
                local subtitle = "Insert Card"
                local subX = math.floor((w - #subtitle) / 2) + 1
                monitor.setCursorPos(subX, 4)
                monitor.write(subtitle)
                
                -- Button
                local btnW = 10
                local btnX = math.floor((w - btnW) / 2) + 1
                ui.drawButton(monitor, btnX, h - 2, btnW, 2, "GET CARD", colors.purple, colors.white)
                
                -- Wait for event or timeout
                local event, side, x, y = os.pullEventRaw()
                
                if event == "monitor_touch" then
                    -- Check if GET CARD button clicked
                    if ui.inBounds(x, y, btnX, h - 2, btnW, 2) then
                        -- Get new player card
                        local players = playerDetector.getPlayersInRange(5)
                        if #players > 0 then
                            local username = players[1]
                            
                            -- Create account if doesn't exist
                            network.request("create_account", {username = username})
                            
                            -- Give player card (assuming you have a dispenser)
                            monitor.setTextScale(0.5)
                            monitor.setBackgroundColor(colors.black)
                            monitor.clear()
                            ui.drawCenteredText(monitor, 5, "Creating card for", colors.black, colors.yellow)
                            ui.drawCenteredText(monitor, 6, username, colors.black, colors.white)
                            
                            redstone.setOutput("right", true)
                            sleep(0.5)
                            redstone.setOutput("right", false)
                            
                            sleep(2)
                        else
                            monitor.setTextScale(0.5)
                            monitor.setBackgroundColor(colors.black)
                            monitor.clear()
                            ui.drawCenteredText(monitor, 6, "No player detected!", colors.black, colors.red)
                            ui.drawCenteredText(monitor, 7, "Stand closer (5 blocks)", colors.black, colors.orange)
                            sleep(2)
                        end
                        break
                    end
                elseif event == "terminate" then
                    error("Terminated")
                end
                
                colorIndex = (colorIndex % #rainbowColors) + 1
                sleep(0.3)
            end
            
            -- Need to recheck username since we broke out of loop
            currentUsername = getPlayerUsername(inventoryManager)
            
            -- If card was detected during animation, loop back to show menu
            if currentUsername then
                -- Continue to next iteration to show the menu
            end
        end
        
        if currentUsername and x then
            -- Card inserted - buttons at scale 0.5
            monitor.setTextScale(0.5)
            local w, h = monitor.getSize()
            local btnW = 17
            local startX = math.floor((w - btnW) / 2)
            
            -- Player card inserted
            if ui.inBounds(x, y, startX, 6, btnW, 3) then
                -- Deposit
                currentBalance = deposit(inventoryManager, monitor, currentUsername, currentBalance)
            elseif ui.inBounds(x, y, startX, 10, btnW, 3) then
                -- Withdraw
                currentBalance = withdraw(inventoryManager, monitor, currentUsername, currentBalance)
            elseif ui.inBounds(x, y, startX, h - 5, btnW, 3) then
                -- Return card
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                ui.drawCenteredText(monitor, 5, "Returning card...", colors.black, colors.yellow)
                ui.drawCenteredText(monitor, 7, "Final Balance:", colors.black, colors.white)
                ui.drawCenteredText(monitor, 8, ui.formatNumber(currentBalance) .. " credits", colors.black, colors.lime)
                
                redstone.setOutput("left", true)
                sleep(0.5)
                redstone.setOutput("left", false)
                
                sleep(2)
                currentUsername = nil
                currentBalance = 0
            end
        end
    end
end

main()
