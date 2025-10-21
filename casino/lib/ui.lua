-- UI Library for Casino Games
-- Handles monitor rendering and touch input

local ui = {}

-- Initialize monitor
function ui.init()
    local monitor = peripheral.find("monitor")
    if not monitor then
        error("No monitor found!")
    end
    
    monitor.setTextScale(0.5)
    monitor.clear()
    
    return monitor
end

-- Draw a box
function ui.drawBox(monitor, x, y, width, height, bgColor, textColor)
    monitor.setBackgroundColor(bgColor or colors.black)
    monitor.setTextColor(textColor or colors.white)
    
    for i = 0, height - 1 do
        monitor.setCursorPos(x, y + i)
        monitor.write(string.rep(" ", width))
    end
end

-- Draw centered text
function ui.drawCenteredText(monitor, y, text, bgColor, textColor)
    local w, h = monitor.getSize()
    monitor.setCursorPos(math.floor((w - #text) / 2) + 1, y)
    monitor.setBackgroundColor(bgColor or colors.black)
    monitor.setTextColor(textColor or colors.white)
    monitor.write(text)
end

-- Draw text at position
function ui.drawText(monitor, x, y, text, bgColor, textColor)
    monitor.setCursorPos(x, y)
    monitor.setBackgroundColor(bgColor or colors.black)
    monitor.setTextColor(textColor or colors.white)
    monitor.write(text)
end

-- Draw button
function ui.drawButton(monitor, x, y, width, height, text, bgColor, textColor)
    ui.drawBox(monitor, x, y, width, height, bgColor, textColor)
    
    -- Center text in button
    local textX = x + math.floor((width - #text) / 2)
    local textY = y + math.floor(height / 2)
    
    monitor.setCursorPos(textX, textY)
    monitor.setTextColor(textColor or colors.white)
    monitor.write(text)
end

-- Check if touch is within bounds
function ui.inBounds(x, y, bx, by, width, height)
    return x >= bx and x < bx + width and y >= by and y < by + height
end

-- Draw idle screen
function ui.drawIdleScreen(monitor, gameName)
    monitor.setBackgroundColor(colors.black)
    monitor.clear()
    
    local w, h = monitor.getSize()
    
    ui.drawCenteredText(monitor, 3, gameName, colors.black, colors.yellow)
    ui.drawCenteredText(monitor, 5, "DROP PLAYER CARD", colors.black, colors.white)
    ui.drawCenteredText(monitor, 6, "TO START", colors.black, colors.white)
end

-- Format number with commas
function ui.formatNumber(num)
    local formatted = tostring(math.floor(num))
    local k
    while true do
        formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
        if k == 0 then
            break
        end
    end
    return formatted
end

return ui
