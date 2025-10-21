-- Slots Game for Casino
-- 3 reels with various symbols and payouts

local network = require("/casino/lib/network")
local ui = require("/casino/lib/ui")

local MIN_BET = 1
local MAX_BET = 100

-- Symbols with weights (lower weight = rarer)
-- Designed for ~99% RTP
local SYMBOLS = {
    {name = "7", display = "7", weight = 1},    -- Rarest
    {name = "Diamond", display = "D", weight = 2},
    {name = "Bell", display = "B", weight = 4},
    {name = "Cherry", display = "C", weight = 8},
    {name = "Lemon", display = "L", weight = 12},
    {name = "Orange", display = "O", weight = 15},
    {name = "Plum", display = "P", weight = 18}
}

-- Payout table (multipliers)
local PAYOUTS = {
    -- Three of a kind
    ["7-7-7"] = 500,
    ["D-D-D"] = 100,
    ["B-B-B"] = 50,
    ["C-C-C"] = 25,
    ["L-L-L"] = 15,
    ["O-O-O"] = 10,
    ["P-P-P"] = 5,
    
    -- Two cherries (any position)
    ["C-C-*"] = 3,
    ["C-*-C"] = 3,
    ["*-C-C"] = 3,
    
    -- One cherry in first reel
    ["C-*-*"] = 2
}

-- Initialize peripherals
local function initPeripherals()
    local monitor = ui.init()
    
    local inventoryManager = peripheral.find("inventoryManager")
    if not inventoryManager then
        error("No inventory manager found!")
    end
    
    local speaker = peripheral.find("speaker")
    local chatBox = peripheral.find("chatBox")
    
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
local function drawSlots(monitor, reels, bet, balance, spinning, message)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Title
    ui.drawCenteredText(monitor, 1, "SLOT MACHINE", colors.black, colors.yellow)
    
    -- Slot display
    local slotY = 4
    ui.drawBox(monitor, 6, slotY, 15, 5, colors.gray, colors.white)
    
    if reels then
        -- Draw reels
        for i, reel in ipairs(reels) do
            local x = 6 + ((i - 1) * 5) + 1
            monitor.setCursorPos(x, slotY + 2)
            monitor.setBackgroundColor(colors.white)
            monitor.setTextColor(colors.black)
            monitor.write(" " .. reel.display .. " ")
        end
    end
    
    if spinning then
        ui.drawCenteredText(monitor, slotY + 2, "SPINNING...", colors.gray, colors.yellow)
    end
    
    -- Bet and balance
    monitor.setCursorPos(2, 10)
    monitor.setBackgroundColor(colors.black)
    monitor.setTextColor(colors.lime)
    monitor.write("Bet: " .. ui.formatNumber(bet))
    monitor.setCursorPos(2, 11)
    monitor.write("Balance: " .. ui.formatNumber(balance))
    
    -- Message
    if message then
        ui.drawCenteredText(monitor, h - 3, message, colors.black, colors.orange)
    end
end

-- Draw betting UI
local function drawBettingUI(monitor, balance, currentBet)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    ui.drawCenteredText(monitor, 1, "SLOT MACHINE", colors.black, colors.yellow)
    
    ui.drawCenteredText(monitor, 4, "Place Your Bet", colors.black, colors.white)
    ui.drawCenteredText(monitor, 5, "Current: " .. ui.formatNumber(currentBet), colors.black, colors.lime)
    ui.drawCenteredText(monitor, 7, "Balance: " .. ui.formatNumber(balance), colors.black, colors.white)
    
    -- Bet buttons
    ui.drawButton(monitor, 2, 9, 6, 1, "+1", colors.green, colors.white)
    ui.drawButton(monitor, 9, 9, 6, 1, "+5", colors.green, colors.white)
    ui.drawButton(monitor, 16, 9, 6, 1, "+10", colors.green, colors.white)
    
    ui.drawButton(monitor, 2, 11, 6, 1, "-1", colors.red, colors.white)
    ui.drawButton(monitor, 9, 11, 6, 1, "-5", colors.red, colors.white)
    ui.drawButton(monitor, 16, 11, 6, 1, "-10", colors.red, colors.white)
    
    ui.drawButton(monitor, 6, h - 1, 10, 1, "SPIN", colors.blue, colors.white)
    ui.drawButton(monitor, w - 11, h - 1, 10, 1, "QUIT", colors.gray, colors.white)
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
local function animateSpin(monitor, pool, speaker)
    local reels = {nil, nil, nil}
    
    -- Spin animation
    for frame = 1, 20 do
        reels = {
            spinReel(pool),
            spinReel(pool),
            spinReel(pool)
        }
        
        drawSlots(monitor, reels, 0, 0, true, nil)
        playSound(speaker, "minecraft:block.note_block.hat", 0.3, 0.8 + (frame * 0.02))
        sleep(0.05)
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
            
            -- Bet adjustment buttons
            if ui.inBounds(x, y, 2, 9, 6, 1) then
                currentBet = math.min(currentBet + 1, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 9, 9, 6, 1) then
                currentBet = math.min(currentBet + 5, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 16, 9, 6, 1) then
                currentBet = math.min(currentBet + 10, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 2, 11, 6, 1) then
                currentBet = math.max(currentBet - 1, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 9, 11, 6, 1) then
                currentBet = math.max(currentBet - 5, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 16, 11, 6, 1) then
                currentBet = math.max(currentBet - 10, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 6, h - 1, 10, 1) then
                -- Spin
                betting = false
            elseif ui.inBounds(x, y, w - 11, h - 1, 10, 1) then
                -- Quit
                return balance
            end
        end
        
        -- Deduct bet from balance
        balance = balance - currentBet
        network.request("subtract_balance", {username = username, amount = currentBet})
        
        -- Spin reels
        local reels = animateSpin(monitor, pool, speaker)
        
        -- Calculate payout
        local payout = calculatePayout(reels, currentBet)
        
        local message = ""
        if payout > 0 then
            balance = balance + payout
            network.request("add_balance", {username = username, amount = payout})
            local profit = payout - currentBet
            message = "WIN! +" .. ui.formatNumber(profit) .. " credits"
            sendNotification(chatBox, username, profit, true, balance)
            playSound(speaker, "minecraft:entity.player.levelup", 1, 1)
        else
            message = "No win. -" .. ui.formatNumber(currentBet)
            sendNotification(chatBox, username, currentBet, false, balance)
            playSound(speaker, "minecraft:entity.villager.no", 0.5, 0.8)
        end
        
        drawSlots(monitor, reels, currentBet, balance, false, message)
        
        -- Show payout table button
        local w, h = monitor.getSize()
        ui.drawButton(monitor, 2, h - 1, 10, 1, "PAYOUTS", colors.purple, colors.white)
        ui.drawButton(monitor, w - 11, h - 1, 10, 1, "QUIT", colors.gray, colors.white)
        
        -- Wait for next spin or quit
        while true do
            local event, side, x, y = os.pullEvent("monitor_touch")
            
            if ui.inBounds(x, y, w - 11, h - 1, 10, 1) then
                -- Quit
                return balance
            elseif ui.inBounds(x, y, 2, h - 1, 10, 1) then
                -- Show payouts
                monitor.setBackgroundColor(colors.black)
                monitor.clear()
                ui.drawCenteredText(monitor, 1, "PAYOUT TABLE", colors.black, colors.yellow)
                
                monitor.setCursorPos(2, 3)
                monitor.setTextColor(colors.white)
                monitor.write("7-7-7: 500x")
                monitor.setCursorPos(2, 4)
                monitor.write("D-D-D: 100x")
                monitor.setCursorPos(2, 5)
                monitor.write("B-B-B: 50x")
                monitor.setCursorPos(2, 6)
                monitor.write("C-C-C: 25x")
                monitor.setCursorPos(2, 7)
                monitor.write("L-L-L: 15x")
                monitor.setCursorPos(2, 8)
                monitor.write("O-O-O: 10x")
                monitor.setCursorPos(2, 9)
                monitor.write("P-P-P: 5x")
                monitor.setCursorPos(2, 10)
                monitor.write("C-C-?: 3x")
                monitor.setCursorPos(2, 11)
                monitor.write("C-?-?: 2x")
                
                ui.drawButton(monitor, 8, h - 1, 10, 1, "BACK", colors.blue, colors.white)
                
                while true do
                    local e, s, bx, by = os.pullEvent("monitor_touch")
                    if ui.inBounds(bx, by, 8, h - 1, 10, 1) then
                        break
                    end
                end
                
                drawSlots(monitor, reels, currentBet, balance, false, message)
                ui.drawButton(monitor, 2, h - 1, 10, 1, "PAYOUTS", colors.purple, colors.white)
                ui.drawButton(monitor, w - 11, h - 1, 10, 1, "QUIT", colors.gray, colors.white)
            else
                -- Any other touch starts new spin
                break
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
        -- Show idle screen
        ui.drawIdleScreen(monitor, "SLOT MACHINE")
        
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
