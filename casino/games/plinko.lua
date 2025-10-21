-- Plinko Game for Casino
-- Drop ball with physics simulation

local network = require("/casino/lib/network")
local ui = require("/casino/lib/ui")

local MIN_BET = 5
local MAX_BET = 50
local ROWS = 16

-- Multipliers for each slot (16 slots)
local MULTIPLIERS = {1000, 130, 26, 9, 4, 2, 0.2, 0.2, 0.2, 0.2, 0.2, 0.2, 2, 4, 9, 26, 130, 1000}

-- Initialize peripherals
local function initPeripherals()
    local monitor = ui.init()
    
    local inventoryManager = peripheral.find("inventory_manager")
    if not inventoryManager then
        error("No inventory manager found!")
    end
    
    local speaker = peripheral.find("speaker")
    local chatBox = peripheral.find("chat_box")
    
    return monitor, inventoryManager, speaker, chatBox
end

-- Simulate plinko drop
local function dropBall(speaker)
    local position = 8.5  -- Start in middle (between pegs)
    local path = {}
    
    for row = 1, ROWS do
        -- 50/50 chance to go left or right
        if math.random() < 0.5 then
            position = position - 0.5
        else
            position = position + 0.5
        end
        
        -- Keep within bounds
        position = math.max(0.5, math.min(17.5, position))
        
        table.insert(path, {row = row, position = position})
        
        -- Play bounce sound
        if speaker then
            speaker.playSound("minecraft:block.stone.hit", 0.3, 0.8 + (row * 0.05))
        end
    end
    
    -- Final slot (1-18)
    local slot = math.floor(position + 0.5)
    slot = math.max(1, math.min(18, slot))
    
    return path, slot
end

-- Draw plinko board
local function drawBoard(monitor, path, currentRow, showResult, slot, multiplier)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Title
    ui.drawCenteredText(monitor, 1, "PLINKO", colors.black, colors.yellow)
    
    -- Draw simplified board (due to monitor size constraints)
    -- We'll show a small representation
    
    if currentRow and currentRow > 0 then
        -- Show ball position
        local displayRow = math.floor((currentRow / ROWS) * 8) + 2
        local displayPos = math.floor(((path[currentRow].position - 0.5) / 17) * 20) + 3
        
        monitor.setCursorPos(displayPos, displayRow)
        monitor.setTextColor(colors.yellow)
        monitor.write("O")
    end
    
    -- Draw multiplier slots at bottom
    local slotY = h - 3
    monitor.setCursorPos(1, slotY)
    monitor.setTextColor(colors.white)
    monitor.write("Multipliers:")
    
    for i = 1, 18 do
        local mult = MULTIPLIERS[i]
        local x = 1 + ((i - 1) % 12) * 2
        local y = slotY + 1 + math.floor((i - 1) / 12)
        
        monitor.setCursorPos(x, y)
        
        -- Color code by multiplier
        if mult >= 100 then
            monitor.setTextColor(colors.red)
        elseif mult >= 10 then
            monitor.setTextColor(colors.orange)
        elseif mult >= 2 then
            monitor.setTextColor(colors.yellow)
        else
            monitor.setTextColor(colors.blue)
        end
        
        if mult >= 10 then
            monitor.write(tostring(math.floor(mult)))
        elseif mult >= 1 then
            monitor.write(tostring(mult))
        else
            monitor.write(".2")
        end
    end
    
    if showResult and slot then
        ui.drawCenteredText(monitor, h - 5, "Slot: " .. slot, colors.black, colors.white)
        ui.drawCenteredText(monitor, h - 4, "Multiplier: " .. multiplier .. "x", colors.black, colors.lime)
    end
end

-- Draw betting UI
local function drawBettingUI(monitor, balance, currentBet)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    ui.drawCenteredText(monitor, 1, "PLINKO", colors.black, colors.yellow)
    
    ui.drawCenteredText(monitor, 4, "Place Your Bet", colors.black, colors.white)
    ui.drawCenteredText(monitor, 5, "Current: " .. ui.formatNumber(currentBet), colors.black, colors.lime)
    ui.drawCenteredText(monitor, 7, "Balance: " .. ui.formatNumber(balance), colors.black, colors.white)
    
    ui.drawCenteredText(monitor, 9, "Min: " .. MIN_BET .. "  Max: " .. MAX_BET, colors.black, colors.gray)
    
    -- Bet buttons
    ui.drawButton(monitor, 2, 11, 6, 1, "+1", colors.green, colors.white)
    ui.drawButton(monitor, 9, 11, 6, 1, "+5", colors.green, colors.white)
    ui.drawButton(monitor, 16, 11, 6, 1, "+10", colors.green, colors.white)
    
    ui.drawButton(monitor, 2, 13, 6, 1, "-1", colors.red, colors.white)
    ui.drawButton(monitor, 9, 13, 6, 1, "-5", colors.red, colors.white)
    ui.drawButton(monitor, 16, 13, 6, 1, "-10", colors.red, colors.white)
    
    ui.drawButton(monitor, 6, h - 1, 10, 1, "DROP", colors.blue, colors.white)
    ui.drawButton(monitor, w - 11, h - 1, 10, 1, "QUIT", colors.gray, colors.white)
end

-- Animate drop
local function animateDrop(monitor, speaker)
    local path, slot = dropBall(speaker)
    
    -- Animate the drop
    for i, step in ipairs(path) do
        drawBoard(monitor, path, i, false, nil, nil)
        sleep(0.1)
    end
    
    -- Show final position
    drawBoard(monitor, path, #path, true, slot, MULTIPLIERS[slot])
    
    return slot
end

-- Send win/loss notification
local function sendNotification(chatBox, username, amount, isWin, balance)
    if not chatBox then return end
    
    local message = isWin and 
        string.format("won %d credits! (Balance: %d)", amount, balance) or
        string.format("lost %d credits. (Balance: %d)", amount, balance)
    
    chatBox.sendToastToPlayer(message, "Plinko", username, "Casino", "[]", "&6")
    
    -- Big win announcement
    if isWin and amount >= 500 then
        local tier = ""
        if amount >= 10000 then
            tier = "&4&lMEGA WIN"
        elseif amount >= 5000 then
            tier = "&c&lHUGE WIN"
        elseif amount >= 2000 then
            tier = "&6&lBIG WIN"
        elseif amount >= 1000 then
            tier = "&e&lGREAT WIN"
        else
            tier = "&eNICE WIN"
        end
        
        chatBox.sendMessage(
            string.format("%s! %s won %s credits at Plinko!", tier, username, ui.formatNumber(amount)),
            "Casino",
            "[]",
            "&6"
        )
    end
end

-- Play sound
local function playSound(speaker, sound, volume, pitch)
    if speaker then
        speaker.playSound(sound, volume or 1, pitch or 1)
    end
end

-- Main game loop
local function playGame(monitor, inventoryManager, speaker, chatBox, username, balance)
    local currentBet = MIN_BET
    
    while true do
        -- Betting phase
        drawBettingUI(monitor, balance, currentBet)
        
        local betting = true
        while betting do
            local event, side, x, y = os.pullEvent("monitor_touch")
            
            local w, h = monitor.getSize()
            
            -- Bet adjustment buttons
            if ui.inBounds(x, y, 2, 11, 6, 1) then
                currentBet = math.min(currentBet + 1, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 9, 11, 6, 1) then
                currentBet = math.min(currentBet + 5, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 16, 11, 6, 1) then
                currentBet = math.min(currentBet + 10, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 2, 13, 6, 1) then
                currentBet = math.max(currentBet - 1, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 9, 13, 6, 1) then
                currentBet = math.max(currentBet - 5, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 16, 13, 6, 1) then
                currentBet = math.max(currentBet - 10, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 6, h - 1, 10, 1) then
                -- Drop
                betting = false
            elseif ui.inBounds(x, y, w - 11, h - 1, 10, 1) then
                -- Quit
                return balance
            end
        end
        
        -- Deduct bet from balance
        balance = balance - currentBet
        network.request("subtract_balance", {username = username, amount = currentBet})
        
        -- Drop ball
        local slot = animateDrop(monitor, speaker)
        local multiplier = MULTIPLIERS[slot]
        
        -- Calculate payout (round down)
        local payout = math.floor(currentBet * multiplier)
        
        local message = ""
        local w, h = monitor.getSize()
        
        if payout > 0 then
            balance = balance + payout
            network.request("add_balance", {username = username, amount = payout})
            
            local profit = payout - currentBet
            if profit > 0 then
                message = "WIN! +" .. ui.formatNumber(profit) .. " credits"
                sendNotification(chatBox, username, profit, true, balance)
                playSound(speaker, "minecraft:entity.player.levelup", 1, 1)
            elseif profit < 0 then
                message = "LOSS! " .. ui.formatNumber(profit) .. " credits"
                sendNotification(chatBox, username, math.abs(profit), false, balance)
                playSound(speaker, "minecraft:entity.villager.no", 0.5, 0.8)
            else
                message = "Break even!"
                playSound(speaker, "minecraft:block.note_block.hat", 0.5, 1)
            end
        else
            message = "LOSS! -" .. ui.formatNumber(currentBet) .. " credits"
            sendNotification(chatBox, username, currentBet, false, balance)
            playSound(speaker, "minecraft:entity.villager.no", 0.5, 0.8)
        end
        
        ui.drawCenteredText(monitor, h - 2, message, colors.black, colors.orange)
        ui.drawCenteredText(monitor, h - 1, "Balance: " .. ui.formatNumber(balance), colors.black, colors.lime)
        
        sleep(3)
        
        -- Check if player has enough balance
        if balance < MIN_BET then
            monitor.setBackgroundColor(colors.black)
            monitor.clear()
            ui.drawCenteredText(monitor, 6, "Insufficient balance!", colors.black, colors.red)
            sleep(3)
            return balance
        end
        
        currentBet = math.min(currentBet, balance, MAX_BET)
    end
end

-- Main program
local function main()
    math.randomseed(os.epoch("utc"))
    
    print("Plinko Game Starting...")
    
    network.init()
    print("Network initialized")
    
    local monitor, inventoryManager, speaker, chatBox = initPeripherals()
    print("Peripherals initialized")
    
    while true do
        -- Show idle screen
        ui.drawIdleScreen(monitor, "PLINKO")
        
        -- Wait for player card
        while true do
            local owner = inventoryManager.getOwner()
            if owner then
                break
            end
            sleep(0.5)
        end
        
        local username = inventoryManager.getOwner()
        print("Player detected: " .. username)
        
        playSound(speaker, "minecraft:block.note_block.pling", 1, 2)
        
        -- Get balance
        local success, data = network.request("get_balance", {username = username})
        if not success then
            ui.drawCenteredText(monitor, 6, "Error loading balance!", colors.black, colors.red)
            sleep(3)
        else
            local balance = data.balance
            
            if balance < MIN_BET then
                ui.drawCenteredText(monitor, 6, "Insufficient balance!", colors.black, colors.red)
                ui.drawCenteredText(monitor, 7, "Visit cashier to deposit", colors.black, colors.white)
                sleep(3)
            else
                -- Play game
                local finalBalance = playGame(monitor, inventoryManager, speaker, chatBox, username, balance)
                
                -- Update balance
                network.request("set_balance", {username = username, balance = finalBalance})
                
                -- Return card
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                ui.drawCenteredText(monitor, 6, "Thanks for playing!", colors.black, colors.yellow)
                ui.drawCenteredText(monitor, 7, "Final: " .. ui.formatNumber(finalBalance) .. " credits", colors.black, colors.lime)
                
                redstone.setOutput("back", true)
                sleep(0.5)
                redstone.setOutput("back", false)
                
                sleep(2)
            end
        end
    end
end

main()
