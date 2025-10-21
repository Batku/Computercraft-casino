-- Blackjack Game for Casino
-- Standard blackjack rules, dealer stands on 17

local network = require("/casino/lib/network")
local ui = require("/casino/lib/ui")

local MIN_BET = 1
local MAX_BET = 1000

-- Card values
local CARDS = {
    {name = "A", value = 11},
    {name = "2", value = 2},
    {name = "3", value = 3},
    {name = "4", value = 4},
    {name = "5", value = 5},
    {name = "6", value = 6},
    {name = "7", value = 7},
    {name = "8", value = 8},
    {name = "9", value = 9},
    {name = "10", value = 10},
    {name = "J", value = 10},
    {name = "Q", value = 10},
    {name = "K", value = 10}
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

-- Calculate hand value
local function calculateHand(hand)
    local value = 0
    local aces = 0
    
    for _, card in ipairs(hand) do
        value = value + card.value
        if card.name == "A" then
            aces = aces + 1
        end
    end
    
    -- Adjust for aces
    while value > 21 and aces > 0 do
        value = value - 10
        aces = aces - 1
    end
    
    return value
end

-- Check if hand is blackjack
local function isBlackjack(hand)
    return #hand == 2 and calculateHand(hand) == 21
end

-- Draw a card
local function drawCard()
    return CARDS[math.random(1, #CARDS)]
end

-- Draw hand on monitor
local function drawHand(monitor, hand, x, y, label, hideFirst)
    monitor.setCursorPos(x, y)
    monitor.setTextColor(colors.white)
    monitor.write(label .. ":")
    
    monitor.setCursorPos(x, y + 1)
    for i, card in ipairs(hand) do
        if hideFirst and i == 1 then
            monitor.write("[?] ")
        else
            monitor.write("[" .. card.name .. "] ")
        end
    end
    
    if not hideFirst then
        monitor.setCursorPos(x, y + 2)
        monitor.write("Total: " .. calculateHand(hand))
    end
end

-- Draw game UI
local function drawGameUI(monitor, playerHand, dealerHand, bet, balance, message, showButtons, hideDealer)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    -- Title
    ui.drawCenteredText(monitor, 1, "BLACKJACK", colors.black, colors.yellow)
    
    -- Dealer hand
    drawHand(monitor, dealerHand, 2, 3, "Dealer", hideDealer)
    
    -- Player hand
    drawHand(monitor, playerHand, 2, 6, "Player", false)
    
    -- Bet and balance
    monitor.setCursorPos(2, 9)
    monitor.setTextColor(colors.lime)
    monitor.write("Bet: " .. ui.formatNumber(bet))
    monitor.setCursorPos(2, 10)
    monitor.write("Balance: " .. ui.formatNumber(balance))
    
    -- Message
    if message then
        ui.drawCenteredText(monitor, h - 3, message, colors.black, colors.orange)
    end
    
    -- Buttons
    if showButtons then
        if showButtons.hit then
            ui.drawButton(monitor, 2, h - 1, 8, 1, "HIT", colors.green, colors.white)
        end
        if showButtons.stand then
            ui.drawButton(monitor, 11, h - 1, 8, 1, "STAND", colors.red, colors.white)
        end
        if showButtons.quit then
            ui.drawButton(monitor, w - 9, h - 1, 8, 1, "QUIT", colors.gray, colors.white)
        end
    end
end

-- Draw betting UI
local function drawBettingUI(monitor, balance, currentBet)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    ui.drawCenteredText(monitor, 1, "BLACKJACK", colors.black, colors.yellow)
    
    ui.drawCenteredText(monitor, 4, "Place Your Bet", colors.black, colors.white)
    ui.drawCenteredText(monitor, 5, "Current: " .. ui.formatNumber(currentBet), colors.black, colors.lime)
    ui.drawCenteredText(monitor, 7, "Balance: " .. ui.formatNumber(balance), colors.black, colors.white)
    
    -- Bet buttons
    ui.drawButton(monitor, 2, 9, 6, 1, "+1", colors.green, colors.white)
    ui.drawButton(monitor, 9, 9, 6, 1, "+10", colors.green, colors.white)
    ui.drawButton(monitor, 16, 9, 6, 1, "+100", colors.green, colors.white)
    
    ui.drawButton(monitor, 2, 11, 6, 1, "-1", colors.red, colors.white)
    ui.drawButton(monitor, 9, 11, 6, 1, "-10", colors.red, colors.white)
    ui.drawButton(monitor, 16, 11, 6, 1, "-100", colors.red, colors.white)
    
    ui.drawButton(monitor, 2, h - 1, 10, 1, "DEAL", colors.blue, colors.white)
    ui.drawButton(monitor, w - 11, h - 1, 10, 1, "QUIT", colors.gray, colors.white)
end

-- Send win/loss notification
local function sendNotification(chatBox, username, amount, isWin, balance)
    if not chatBox then return end
    
    local message = isWin and 
        string.format("won %d credits! (Balance: %d)", amount, balance) or
        string.format("lost %d credits. (Balance: %d)", amount, balance)
    
    chatBox.sendToastToPlayer(message, "Blackjack", username, "Casino", "[]", "&6")
    
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
            string.format("%s! %s won %s credits at Blackjack!", tier, username, ui.formatNumber(amount)),
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
            if ui.inBounds(x, y, 2, 9, 6, 1) then
                currentBet = math.min(currentBet + 1, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 9, 9, 6, 1) then
                currentBet = math.min(currentBet + 10, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 16, 9, 6, 1) then
                currentBet = math.min(currentBet + 100, balance, MAX_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 2, 11, 6, 1) then
                currentBet = math.max(currentBet - 1, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 9, 11, 6, 1) then
                currentBet = math.max(currentBet - 10, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 16, 11, 6, 1) then
                currentBet = math.max(currentBet - 100, MIN_BET)
                drawBettingUI(monitor, balance, currentBet)
            elseif ui.inBounds(x, y, 2, h - 1, 10, 1) then
                -- Deal
                betting = false
            elseif ui.inBounds(x, y, w - 11, h - 1, 10, 1) then
                -- Quit
                return balance
            end
        end
        
        -- Deduct bet from balance
        balance = balance - currentBet
        network.request("subtract_balance", {username = username, amount = currentBet})
        
        -- Deal initial cards
        local playerHand = {drawCard(), drawCard()}
        local dealerHand = {drawCard(), drawCard()}
        
        playSound(speaker, "minecraft:entity.item.pickup", 0.5, 1)
        
        -- Check for immediate blackjack
        local playerBJ = isBlackjack(playerHand)
        local dealerBJ = isBlackjack(dealerHand)
        
        if playerBJ and dealerBJ then
            -- Push
            drawGameUI(monitor, playerHand, dealerHand, currentBet, balance, "Push! Both blackjack!", {quit = true}, false)
            balance = balance + currentBet
            network.request("add_balance", {username = username, amount = currentBet})
            playSound(speaker, "minecraft:block.note_block.hat", 0.5, 1)
        elseif playerBJ then
            -- Player blackjack! Pays 3:2
            local winAmount = math.floor(currentBet * 2.5)
            balance = balance + winAmount
            network.request("add_balance", {username = username, amount = winAmount})
            drawGameUI(monitor, playerHand, dealerHand, currentBet, balance, "BLACKJACK! +" .. ui.formatNumber(winAmount - currentBet), {quit = true}, false)
            sendNotification(chatBox, username, winAmount - currentBet, true, balance)
            playSound(speaker, "minecraft:entity.player.levelup", 1, 1.2)
        elseif dealerBJ then
            -- Dealer blackjack
            drawGameUI(monitor, playerHand, dealerHand, currentBet, balance, "Dealer Blackjack! -" .. ui.formatNumber(currentBet), {quit = true}, false)
            sendNotification(chatBox, username, currentBet, false, balance)
            playSound(speaker, "minecraft:entity.villager.no", 0.5, 0.8)
        else
            -- Normal play
            local playing = true
            local playerBust = false
            
            while playing do
                drawGameUI(monitor, playerHand, dealerHand, currentBet, balance, "Hit or Stand?", {hit = true, stand = true, quit = true}, true)
                
                local event, side, x, y = os.pullEvent("monitor_touch")
                local w, h = monitor.getSize()
                
                if ui.inBounds(x, y, 2, h - 1, 8, 1) then
                    -- Hit
                    table.insert(playerHand, drawCard())
                    playSound(speaker, "minecraft:entity.item.pickup", 0.5, 1.2)
                    
                    local playerValue = calculateHand(playerHand)
                    if playerValue > 21 then
                        -- Bust
                        drawGameUI(monitor, playerHand, dealerHand, currentBet, balance, "BUST! -" .. ui.formatNumber(currentBet), {quit = true}, false)
                        sendNotification(chatBox, username, currentBet, false, balance)
                        playSound(speaker, "minecraft:entity.villager.no", 0.5, 0.8)
                        playerBust = true
                        playing = false
                    elseif playerValue == 21 then
                        -- Auto-stand on 21
                        playing = false
                    end
                elseif ui.inBounds(x, y, 11, h - 1, 8, 1) then
                    -- Stand
                    playing = false
                elseif ui.inBounds(x, y, w - 9, h - 1, 8, 1) then
                    -- Quit (forfeit hand)
                    return balance
                end
            end
            
            -- Dealer plays (if player didn't bust)
            if not playerBust then
                drawGameUI(monitor, playerHand, dealerHand, currentBet, balance, "Dealer playing...", {}, false)
                sleep(1)
                
                while calculateHand(dealerHand) < 17 do
                    table.insert(dealerHand, drawCard())
                    playSound(speaker, "minecraft:entity.item.pickup", 0.5, 0.8)
                    drawGameUI(monitor, playerHand, dealerHand, currentBet, balance, "Dealer playing...", {}, false)
                    sleep(1)
                end
                
                local playerValue = calculateHand(playerHand)
                local dealerValue = calculateHand(dealerHand)
                
                local message = ""
                if dealerValue > 21 then
                    -- Dealer bust
                    local winAmount = currentBet * 2
                    balance = balance + winAmount
                    network.request("add_balance", {username = username, amount = winAmount})
                    message = "Dealer BUST! +" .. ui.formatNumber(currentBet)
                    sendNotification(chatBox, username, currentBet, true, balance)
                    playSound(speaker, "minecraft:entity.player.levelup", 1, 1)
                elseif playerValue > dealerValue then
                    -- Player wins
                    local winAmount = currentBet * 2
                    balance = balance + winAmount
                    network.request("add_balance", {username = username, amount = winAmount})
                    message = "YOU WIN! +" .. ui.formatNumber(currentBet)
                    sendNotification(chatBox, username, currentBet, true, balance)
                    playSound(speaker, "minecraft:entity.player.levelup", 1, 1)
                elseif playerValue < dealerValue then
                    -- Dealer wins
                    message = "Dealer Wins! -" .. ui.formatNumber(currentBet)
                    sendNotification(chatBox, username, currentBet, false, balance)
                    playSound(speaker, "minecraft:entity.villager.no", 0.5, 0.8)
                else
                    -- Push
                    balance = balance + currentBet
                    network.request("add_balance", {username = username, amount = currentBet})
                    message = "Push!"
                    playSound(speaker, "minecraft:block.note_block.hat", 0.5, 1)
                end
                
                drawGameUI(monitor, playerHand, dealerHand, currentBet, balance, message, {quit = true}, false)
            end
        end
        
        -- Wait for next round or quit
        while true do
            local event, side, x, y = os.pullEvent("monitor_touch")
            local w, h = monitor.getSize()
            
            if ui.inBounds(x, y, w - 9, h - 1, 8, 1) then
                return balance
            else
                -- Any other touch starts new round
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
    
    print("Blackjack Game Starting...")
    
    network.init()
    print("Network initialized")
    
    local monitor, inventoryManager, speaker, chatBox = initPeripherals()
    print("Peripherals initialized")
    
    while true do
        -- Show idle screen
        ui.drawIdleScreen(monitor, "BLACKJACK")
        
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
