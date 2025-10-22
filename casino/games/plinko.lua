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
local function drawBoard(monitor, bet, balance, path, currentRow, showResult, slot, multiplier, payout)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Title
    ui.drawCenteredText(monitor, 1, "PLINKO", colors.black, colors.yellow)
    
    -- Bet on left
    monitor.setCursorPos(2, 2)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.lime)
    monitor.write("Bet: " .. ui.formatNumber(bet))
    
    -- Draw board visualization - MUCH BIGGER, fills almost entire screen
    local boardStartY = 2
    local boardHeight = h - 5  -- Fill most of screen height, leave room for multipliers
    local boardWidth = w - 2
    local boardStartX = 1
    
    if currentRow and currentRow > 0 then
        -- Show ball dropping
        local displayRow = math.floor((currentRow / ROWS) * boardHeight) + boardStartY
        local displayPos = boardStartX + math.floor(((path[currentRow].position) / 17) * (boardWidth - 1))
        
        -- Draw the ball (centered and visible)
        monitor.setCursorPos(displayPos, displayRow)
        monitor.setBackgroundColor(colors.yellow)
        monitor.setTextColor(colors.black)
        monitor.write("O")
        monitor.setBackgroundColor(colors.black)
        
        -- Draw pegs in triangle pattern (fewer, bigger spacing to match ball movement)
        for row = 0, ROWS - 1 do
            local rowY = boardStartY + math.floor((row / ROWS) * boardHeight)
            local pegsInRow = math.min(row + 3, 18)
            for i = 0, pegsInRow - 1 do
                local pegPos = math.floor(boardStartX + ((i / (pegsInRow - 1)) * (boardWidth - 1)))
                if pegPos ~= displayPos or rowY ~= displayRow then
                    monitor.setCursorPos(pegPos, rowY)
                    monitor.setTextColor(colors.gray)
                    monitor.write("o")  -- Bigger dot character
                end
            end
        end
    end
    
    -- Balance at bottom right during gameplay
    monitor.setCursorPos(w - #("Bal: " .. ui.formatNumber(balance)) - 1, h - 1)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.lime)
    monitor.write("Bal: " .. ui.formatNumber(balance))
    
    -- Draw multiplier slots at bottom in correct positions (18 slots across bottom)
    local slotY = h - 2
    
    -- Draw each multiplier directly below its corresponding slot position
    for i = 1, 18 do
        local mult = MULTIPLIERS[i]
        -- Position multipliers evenly across the width
        local x = math.floor(2 + ((i - 1) * (w - 4) / 17))
        
        monitor.setCursorPos(x, slotY)
        
        -- Color code by multiplier
        local color = colors.white
        if mult >= 100 then
            color = colors.red
        elseif mult >= 10 then
            color = colors.orange
        elseif mult >= 2 then
            color = colors.yellow
        else
            color = colors.blue
        end
        
        -- Highlight winning slot
        if showResult and slot == i then
            monitor.setBackgroundColor(color)
            monitor.setTextColor(colors.black)
        else
            monitor.setBackgroundColor(colors.black)
            monitor.setTextColor(color)
        end
        
        -- Format multiplier text
        if mult >= 100 then
            monitor.write(string.format("%dX", math.floor(mult)))
        elseif mult >= 10 then
            monitor.write(string.format("%dX", math.floor(mult)))
        elseif mult >= 1 then
            monitor.write(string.format("%dX", math.floor(mult)))
        else
            monitor.write(".2")
        end
        monitor.setBackgroundColor(colors.black)
    end
    
    if showResult and slot and payout then
        monitor.setCursorPos(2, h - 3)
        monitor.setBackgroundColor(colors.black)
        monitor.setTextColor(colors.white)
        monitor.write("Slot " .. slot .. " = " .. multiplier .. "x")
        
        local profit = payout - bet
        if profit > 0 then
            monitor.setCursorPos(w - #("+" .. ui.formatNumber(profit)) - 1, h - 3)
            monitor.setTextColor(colors.lime)
            monitor.write("+" .. ui.formatNumber(profit))
        elseif profit < 0 then
            monitor.setCursorPos(w - #(ui.formatNumber(profit)) - 1, h - 3)
            monitor.setTextColor(colors.red)
            monitor.write(ui.formatNumber(profit))
        end
    end
end

-- Draw betting UI
local function drawBettingUI(monitor, balance, currentBet)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    ui.drawCenteredText(monitor, 1, "PLINKO", colors.black, colors.yellow)
    
    -- Large centered bet display
    ui.drawCenteredText(monitor, 4, "PLACE YOUR BET", colors.black, colors.white)
    
    -- LARGE bet amount in center
    monitor.setCursorPos(1, 6)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.lime)
    local betText = ui.formatNumber(currentBet)
    local betX = math.floor((w - #betText) / 2)
    monitor.setCursorPos(betX, 6)
    monitor.setTextScale(1)
    monitor.write(betText)
    
    -- LARGE balance in center
    ui.drawCenteredText(monitor, 8, "Balance: " .. ui.formatNumber(balance), colors.black, colors.white)
    ui.drawCenteredText(monitor, 9, "Min: " .. MIN_BET .. "  Max: " .. MAX_BET, colors.black, colors.gray)
    
    -- Bet buttons (bigger and centered, moved lower)
    local btnW = 7
    local startX = math.floor((w - (btnW * 3 + 2)) / 2)
    
    ui.drawButton(monitor, startX, h - 11, btnW, 2, "+1", colors.green, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, h - 11, btnW, 2, "+5", colors.green, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, h - 11, btnW, 2, "+10", colors.green, colors.white)
    
    ui.drawButton(monitor, startX, h - 8, btnW, 2, "-1", colors.red, colors.white)
    ui.drawButton(monitor, startX + btnW + 1, h - 8, btnW, 2, "-5", colors.red, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, h - 8, btnW, 2, "-10", colors.red, colors.white)
    
    -- MIN and MAX buttons
    ui.drawButton(monitor, startX, h - 5, btnW, 2, "MIN", colors.orange, colors.white)
    ui.drawButton(monitor, startX + (btnW + 1) * 2, h - 5, btnW, 2, "MAX", colors.orange, colors.white)
    
    -- Action buttons at very bottom (DROP centered and wider)
    local dropW = 12
    local dropX = math.floor((w - dropW) / 2)
    ui.drawButton(monitor, dropX, h - 3, dropW, 3, "DROP", colors.blue, colors.white)
    ui.drawButton(monitor, w - 10, h - 3, 9, 3, "QUIT", colors.gray, colors.white)
end

-- Animate drop
local function animateDrop(monitor, speaker, bet, balance)
    local path, slot = dropBall(speaker)
    
    -- Animate the drop
    for i, step in ipairs(path) do
        drawBoard(monitor, bet, balance, path, i, false, nil, nil, nil)
        sleep(0.1)
    end
    
    -- Calculate payout
    local multiplier = MULTIPLIERS[slot]
    local payout = math.floor(bet * multiplier)
    
    -- Show final position with payout
    drawBoard(monitor, bet, balance, path, #path, true, slot, multiplier, payout)
    
    return slot, payout
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
            local btnW = 7
            local startX = math.floor((w - (btnW * 3 + 2)) / 2)
            local dropW = 12
            local dropX = math.floor((w - dropW) / 2)
            
            -- Bet adjustment buttons
            if ui.inBounds(x, y, startX, h - 11, btnW, 2) then
                currentBet = math.min(currentBet + 1, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, startX + btnW + 1, h - 11, btnW, 2) then
                currentBet = math.min(currentBet + 5, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, h - 11, btnW, 2) then
                currentBet = math.min(currentBet + 10, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, startX, h - 8, btnW, 2) then
                currentBet = math.max(currentBet - 1, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, startX + btnW + 1, h - 8, btnW, 2) then
                currentBet = math.max(currentBet - 5, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, h - 8, btnW, 2) then
                currentBet = math.max(currentBet - 10, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, startX, h - 5, btnW, 2) then
                -- MIN
                currentBet = MIN_BET
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, startX + (btnW + 1) * 2, h - 5, btnW, 2) then
                -- MAX
                currentBet = math.min(balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, dropX, h - 3, dropW, 3) then
                -- Drop
                betting = false
            elseif ui.inBounds(x, y, w - 10, h - 3, 9, 3) then
                -- Quit
                return balance
            end
        end
        
        -- Deduct bet from balance
        balance = balance - currentBet
        network.request("subtract_balance", {username = username, amount = currentBet})
        
        -- Drop ball
        local slot, payout = animateDrop(monitor, speaker, currentBet, balance)
        
        local profit = payout - currentBet
        if payout > 0 then
            balance = balance + payout
            network.request("add_balance", {username = username, amount = payout})
            
            if profit > 0 then
                sendNotification(chatBox, username, profit, true, balance)
                playSound(speaker, "minecraft:entity.player.levelup", 1, 1)
            elseif profit < 0 then
                sendNotification(chatBox, username, math.abs(profit), false, balance)
                playSound(speaker, "minecraft:entity.villager.no", 0.5, 0.8)
            else
                playSound(speaker, "minecraft:block.note_block.hat", 0.5, 1)
            end
        else
            sendNotification(chatBox, username, currentBet, false, balance)
            playSound(speaker, "minecraft:entity.villager.no", 0.5, 0.8)
        end
        
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
