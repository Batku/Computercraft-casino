-- Slots Game for Casino
-- 3 reels with various symbols and payouts

local network = require("/casino/lib/network")
local ui = require("/casino/lib/ui")

local MIN_BET = 1
local MAX_BET = 100

-- Symbols with weights (lower weight = rarer)
-- Designed for ~99% RTP
local SYMBOLS = {
    {name = "7", display = string.char(7), weight = 1},      -- Bell symbol (rarest)
    {name = "Diamond", display = string.char(4), weight = 2}, -- Diamond ♦
    {name = "Bell", display = string.char(11), weight = 4},   -- Male symbol ♂
    {name = "Cherry", display = string.char(3), weight = 8},  -- Heart ♥
    {name = "Lemon", display = string.char(15), weight = 12}, -- Sun ☼
    {name = "Orange", display = string.char(164), weight = 15}, -- Circle ○
    {name = "Plum", display = string.char(6), weight = 18}    -- Spade ♠
}

-- Payout table (multipliers)
local PAYOUTS = {
    -- Three of a kind
    ["7-7-7"] = 500,
    ["Diamond-Diamond-Diamond"] = 100,
    ["Bell-Bell-Bell"] = 50,
    ["Cherry-Cherry-Cherry"] = 25,
    ["Lemon-Lemon-Lemon"] = 15,
    ["Orange-Orange-Orange"] = 10,
    ["Plum-Plum-Plum"] = 5,
    
    -- Two cherries (any position)
    ["Cherry-Cherry-*"] = 3,
    ["Cherry-*-Cherry"] = 3,
    ["*-Cherry-Cherry"] = 3,
    
    -- One cherry in first reel
    ["Cherry-*-*"] = 2
}

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

-- Build weighted symbol list
local function buildSymbolPool()
    local pool = {}
    for _, symbol in ipairs(SYMBOLS) do
        for i = 1, symbol.weight do
            table.insert(pool, symbol)
        end
    end
    return pool
end

-- Spin reel
local function spinReel(pool)
    return pool[math.random(1, #pool)]
end

-- Calculate payout
local function calculatePayout(reels, bet)
    local pattern = reels[1].name .. "-" .. reels[2].name .. "-" .. reels[3].name
    
    -- Check exact matches
    if PAYOUTS[pattern] then
        return math.floor(bet * PAYOUTS[pattern])
    end
    
    -- Check wildcard patterns
    for patternKey, multiplier in pairs(PAYOUTS) do
        if patternKey:find("*") then
            local match = true
            local parts = {}
            for part in patternKey:gmatch("[^-]+") do
                table.insert(parts, part)
            end
            
            for i = 1, 3 do
                if parts[i] ~= "*" and parts[i] ~= reels[i].name then
                    match = false
                    break
                end
            end
            
            if match then
                return math.floor(bet * multiplier)
            end
        end
    end
    
    return 0
end

-- Draw slot machine
local function drawSlots(monitor, reels, bet, balance, spinning, message, showButtons)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Title with spacing
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.orange)
    local title = "S L O T S"
    local titleX = math.floor((w - #title) / 2)
    monitor.setCursorPos(titleX, 1)
    monitor.write(title)
    
    -- Bet on left
    monitor.setCursorPos(2, 2)
    monitor.setTextColor(colors.lime)
    monitor.write("Bet: " .. ui.formatNumber(bet))
    
    -- Balance on right
    monitor.setCursorPos(w - #("Bal: " .. ui.formatNumber(balance)) - 1, 2)
    monitor.write("Bal: " .. ui.formatNumber(balance))
    
    -- Slot display (MUCH BIGGER and centered)
    local slotY = 5
    local slotW = 23
    local slotX = math.floor((w - slotW) / 2)
    
    ui.drawBox(monitor, slotX, slotY, slotW, 9, colors.gray, colors.white)
    
    if reels then
        -- Draw reels with colors (MUCH BIGGER)
        for i, reel in ipairs(reels) do
            local x = slotX + 2 + ((i - 1) * 7)
            
            -- Color based on symbol
            local symbolColor = colors.white
            if reel.name == "7" then
                symbolColor = colors.red
            elseif reel.name == "Diamond" then
                symbolColor = colors.cyan
            elseif reel.name == "Bell" then
                symbolColor = colors.yellow
            elseif reel.name == "Cherry" then
                symbolColor = colors.pink
            elseif reel.name == "Lemon" then
                symbolColor = colors.lime
            elseif reel.name == "Orange" then
                symbolColor = colors.orange
            elseif reel.name == "Plum" then
                symbolColor = colors.purple
            end
            
            -- Draw bigger symbol box (6 wide x 5 tall)
            ui.drawBox(monitor, x, slotY + 2, 6, 5, symbolColor, colors.black)
            
            -- Draw symbol BIGGER in center (3 lines for bigger look)
            monitor.setBackgroundColor(symbolColor)
            monitor.setTextColor(colors.black)
            
            monitor.setCursorPos(x + 2, slotY + 3)
            monitor.write("  ")
            monitor.setCursorPos(x + 1, slotY + 4)
            monitor.write("  " .. reel.display .. "  ")
            monitor.setCursorPos(x + 2, slotY + 5)
            monitor.write("  ")
            
            monitor.setBackgroundColor(colors.black)
        end
    end
    
    -- Message (higher up to avoid button overlap)
    if message then
        monitor.setCursorPos(2, h - 5)
        monitor.setBackgroundColor(colors.black)
        local msgColor = message:find("WIN") and colors.lime or colors.red
        monitor.setTextColor(msgColor)
        monitor.write(message)
    end
    
    -- Buttons at bottom (CHANGE BET and SPIN)
    if showButtons and not spinning then
        local btnW = 10
        local spacing = 2
        local totalW = (btnW * 2) + spacing
        local startX = math.floor((w - totalW) / 2)
        
        ui.drawButton(monitor, startX, h - 3, btnW, 3, "CHANGE BET", colors.orange, colors.white)
        ui.drawButton(monitor, startX + btnW + spacing, h - 3, btnW, 3, "SPIN", colors.blue, colors.white)
        
        -- QUIT button in bottom left corner
        ui.drawButton(monitor, 2, h - 3, 6, 3, "QUIT", colors.gray, colors.white)
        
        -- PAYOUTS button in bottom right corner
        ui.drawButton(monitor, w - 9, h - 3, 8, 3, "PAYOUTS", colors.purple, colors.white)
    end
end

-- Draw payouts screen
local function drawPayoutsScreen(monitor)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Title
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.orange)
    local title = "P A Y O U T S"
    local titleX = math.floor((w - #title) / 2)
    monitor.setCursorPos(titleX, 1)
    monitor.write(title)
    
    ui.drawCenteredText(monitor, 2, "-------------------", colors.black, colors.yellow)
    
    -- Payout table
    local y = 4
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.red)
    monitor.write(string.char(7) .. " " .. string.char(7) .. " " .. string.char(7))
    monitor.setTextColor(colors.white)
    monitor.write(" = 500x")
    
    y = y + 1
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.cyan)
    monitor.write(string.char(4) .. " " .. string.char(4) .. " " .. string.char(4))
    monitor.setTextColor(colors.white)
    monitor.write(" = 100x")
    
    y = y + 1
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.yellow)
    monitor.write(string.char(11) .. " " .. string.char(11) .. " " .. string.char(11))
    monitor.setTextColor(colors.white)
    monitor.write(" = 50x")
    
    y = y + 1
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.pink)
    monitor.write(string.char(3) .. " " .. string.char(3) .. " " .. string.char(3))
    monitor.setTextColor(colors.white)
    monitor.write(" = 25x")
    
    y = y + 1
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.lime)
    monitor.write(string.char(15) .. " " .. string.char(15) .. " " .. string.char(15))
    monitor.setTextColor(colors.white)
    monitor.write(" = 15x")
    
    y = y + 1
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.orange)
    monitor.write(string.char(164) .. " " .. string.char(164) .. " " .. string.char(164))
    monitor.setTextColor(colors.white)
    monitor.write(" = 10x")
    
    y = y + 1
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.purple)
    monitor.write(string.char(6) .. " " .. string.char(6) .. " " .. string.char(6))
    monitor.setTextColor(colors.white)
    monitor.write(" = 5x")
    
    y = y + 2
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.pink)
    monitor.write(string.char(3) .. " " .. string.char(3))
    monitor.setTextColor(colors.gray)
    monitor.write(" *")
    monitor.setTextColor(colors.white)
    monitor.write(" = 3x")
    
    y = y + 1
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.pink)
    monitor.write(string.char(3))
    monitor.setTextColor(colors.gray)
    monitor.write(" * ")
    monitor.setTextColor(colors.pink)
    monitor.write(string.char(3))
    monitor.setTextColor(colors.white)
    monitor.write(" = 3x")
    
    y = y + 1
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.gray)
    monitor.write("* ")
    monitor.setTextColor(colors.pink)
    monitor.write(string.char(3) .. " " .. string.char(3))
    monitor.setTextColor(colors.white)
    monitor.write(" = 3x")
    
    y = y + 2
    monitor.setCursorPos(2, y)
    monitor.setTextColor(colors.pink)
    monitor.write(string.char(3))
    monitor.setTextColor(colors.gray)
    monitor.write(" * *")
    monitor.setTextColor(colors.white)
    monitor.write(" = 2x")
    
    -- Back button
    ui.drawButton(monitor, 2, h - 3, 6, 3, "BACK", colors.blue, colors.white)
end

-- Draw betting UI
local function drawBettingUI(monitor, balance, currentBet)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Fancy title
    monitor.setCursorPos(1, 1)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.orange)
    local title = "S L O T S"
    local titleX = math.floor((w - #title) / 2)
    monitor.setCursorPos(titleX, 1)
    monitor.write(title)
    
    -- Decorative border
    ui.drawCenteredText(monitor, 2, "-------------------", colors.black, colors.yellow)
    
    -- Large centered bet display with fancy styling
    ui.drawCenteredText(monitor, 4, "~~ PLACE YOUR BET ~~", colors.black, colors.yellow)
    
    -- LARGE bet amount in center
    monitor.setCursorPos(1, 6)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.lime)
    local betText = ui.formatNumber(currentBet)
    local betX = math.floor((w - #betText) / 2)
    monitor.setCursorPos(betX, 6)
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
    
    -- Action buttons at very bottom (SPIN centered and wider)
    local spinW = 12
    local spinX = math.floor((w - spinW) / 2)
    ui.drawButton(monitor, spinX, h - 3, spinW, 3, "SPIN", colors.blue, colors.white)
    
    -- QUIT button in bottom left corner
    ui.drawButton(monitor, 2, h - 3, 6, 3, "QUIT", colors.gray, colors.white)
end

-- Send win/loss notification
local function sendNotification(chatBox, username, amount, isWin, balance)
    if not chatBox then return end
    
    local message = isWin and 
        string.format("won %d credits! (Balance: %d)", amount, balance) or
        string.format("lost %d credits. (Balance: %d)", amount, balance)
    
    chatBox.sendToastToPlayer(message, "Slots", username, "Casino", "[]", "&6")
    
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
            string.format("%s! %s won %s credits at Slots!", tier, username, ui.formatNumber(amount)),
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

-- Animate spin
local function animateSpin(monitor, pool, speaker, bet, balance)
    local reels = {nil, nil, nil}
    
    -- Spin animation with ACTUAL random symbols and colors
    for frame = 1, 25 do
        reels = {
            spinReel(pool),
            spinReel(pool),
            spinReel(pool)
        }
        
        drawSlots(monitor, reels, bet, balance, false, nil, false)
        playSound(speaker, "minecraft:block.note_block.hat", 0.3, 0.8 + (frame * 0.02))
        sleep(0.04)
    end
    
    -- Final result with dramatic pause
    sleep(0.3)
    playSound(speaker, "minecraft:block.note_block.bell", 1, 1)
    
    return reels
end

-- Main game loop
local function playGame(monitor, inventoryManager, speaker, chatBox, username, balance)
    local pool = buildSymbolPool()
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
            local spinW = 12
            local spinX = math.floor((w - spinW) / 2)
            
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
            elseif ui.inBounds(x, y, spinX, h - 3, spinW, 3) then
                -- Spin (set bet and go to gameplay)
                betting = false
            elseif ui.inBounds(x, y, 2, h - 3, 6, 3) then
                -- Quit
                return balance
            end
        end
        
        -- Now in gameplay mode - show slots with CHANGE BET and SPIN buttons
        while true do
            -- Show slots with buttons
            drawSlots(monitor, nil, currentBet, balance, false, nil, true)
            
            local event, side, x, y = os.pullEvent("monitor_touch")
            local w, h = monitor.getSize()
            local btnW = 10
            local spacing = 2
            local totalW = (btnW * 2) + spacing
            local startX = math.floor((w - totalW) / 2)
            
            if ui.inBounds(x, y, startX, h - 3, btnW, 3) then
                -- CHANGE BET - go back to betting screen
                break
            elseif ui.inBounds(x, y, 2, h - 3, 6, 3) then
                -- QUIT
                return balance
            elseif ui.inBounds(x, y, w - 9, h - 3, 8, 3) then
                -- PAYOUTS - show payout table
                drawPayoutsScreen(monitor)
                while true do
                    local evt, s, px, py = os.pullEvent("monitor_touch")
                    if ui.inBounds(px, py, 2, h - 3, 6, 3) then
                        -- BACK button clicked
                        break
                    end
                end
                -- Redraw slots screen after returning from payouts
                drawSlots(monitor, nil, currentBet, balance, false, nil, true)
            elseif ui.inBounds(x, y, startX + btnW + spacing, h - 3, btnW, 3) then
                -- SPIN - play the game
                -- Deduct bet from balance
                balance = balance - currentBet
                network.request("subtract_balance", {username = username, amount = currentBet})
                
                -- Spin reels with animation showing bet and balance
                local reels = animateSpin(monitor, pool, speaker, currentBet, balance)
                
                -- Calculate payout
                local payout = calculatePayout(reels, currentBet)
                
                local message = ""
                if payout > 0 then
                    balance = balance + payout
                    network.request("add_balance", {username = username, amount = payout})
                    local profit = payout - currentBet
                    message = "WIN! +" .. ui.formatNumber(profit)
                    sendNotification(chatBox, username, profit, true, balance)
                    playSound(speaker, "minecraft:entity.player.levelup", 1, 1)
                else
                    message = "No win. -" .. ui.formatNumber(currentBet)
                    sendNotification(chatBox, username, currentBet, false, balance)
                    playSound(speaker, "minecraft:entity.villager.no", 0.5, 0.8)
                end
                
                drawSlots(monitor, reels, currentBet, balance, false, message, true)
                
                -- Show result and wait for SPIN click to skip or timeout
                local skipTimer = os.startTimer(2)
                while true do
                    local event2, param1, param2, param3 = os.pullEvent()
                    
                    if event2 == "timer" and param1 == skipTimer then
                        break  -- 2 second timeout
                    elseif event2 == "monitor_touch" then
                        -- Check if SPIN button was clicked to skip
                        if ui.inBounds(param2, param3, startX + btnW + spacing, h - 3, btnW, 3) then
                            os.cancelTimer(skipTimer)
                            break  -- Skip immediately
                        end
                    end
                end
                
                -- Check if player has enough balance
                if balance < MIN_BET then
                    monitor.setBackgroundColor(colors.black)
                    monitor.clear()
                    ui.drawCenteredText(monitor, 6, "Insufficient balance!", colors.black, colors.red)
                    sleep(3)
                    return balance
                end
                
                currentBet = math.min(currentBet, balance, MAX_BET)
                -- Stay in gameplay loop to allow multiple spins
            end
        end
    end
end

-- Main program
local function main()
    math.randomseed(os.epoch("utc"))
    
    print("Slots Game Starting...")
    
    network.init()
    print("Network initialized")
    
    local monitor, inventoryManager, speaker, chatBox = initPeripherals()
    print("Peripherals initialized")
    
    while true do
        -- Show simple idle screen with BIG text
        monitor.setBackgroundColor(colors.black)
        monitor.clear()
        monitor.setTextScale(2)  -- BIG text for idle screen
        
        local w, h = monitor.getSize()
        
        -- Min/Max bet info (centered)
        monitor.setCursorPos(1, 3)
        monitor.setTextColor(colors.white)
        ui.drawCenteredText(monitor, 3, "Min: " .. MIN_BET, colors.black, colors.white)
        
        monitor.setCursorPos(1, 4)
        ui.drawCenteredText(monitor, 4, "Max: " .. MAX_BET, colors.black, colors.white)
        
        -- Animated "DROP CARD" prompt
        local frame = math.floor(os.epoch("utc") / 500) % 2
        if frame == 0 then
            ui.drawCenteredText(monitor, 6, "DROP CARD", colors.black, colors.lime)
        else
            ui.drawCenteredText(monitor, 6, "DROP CARD", colors.black, colors.green)
        end
        
        monitor.setCursorPos(1, 7)
        monitor.setTextColor(colors.white)
        ui.drawCenteredText(monitor, 7, "to play!", colors.black, colors.white)
        
        -- Wait for player card
        while true do
            local owner = inventoryManager.getOwner()
            if owner then
                monitor.setTextScale(1)  -- Reset to normal size
                break
            end
            sleep(0.5)
            
            -- Redraw for animation
            local newFrame = math.floor(os.epoch("utc") / 500) % 2
            if newFrame ~= frame then
                frame = newFrame
                monitor.setTextScale(2)
                if frame == 0 then
                    ui.drawCenteredText(monitor, 6, "DROP CARD", colors.black, colors.lime)
                else
                    ui.drawCenteredText(monitor, 6, "DROP CARD", colors.black, colors.green)
                end
            end
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
                redstone.setOutput("back", true)
                sleep(0.5)
                redstone.setOutput("back", false)
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
