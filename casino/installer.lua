-- Casino System Installer
-- Downloads all files from GitHub automatically
-- Usage: installer.lua <machine-type>
-- Types: server, cashier, blackjack, slots, plinko

local GITHUB_RAW = "https://raw.githubusercontent.com/Batku/Computercraft-casino/main/casino/"

local args = {...}
local machineType = args[1]

if not machineType then
    print("Usage: installer.lua <type>")
    print("Types: server, cashier, blackjack, slots, plinko")
    return
end

local function download(url, path)
    print("Downloading " .. path .. "...")
    
    -- Create directories if needed
    local dir = path:match("(.*/)")
    if dir then
        fs.makeDir(dir)
    end
    
    local response = http.get(url)
    if not response then
        error("Failed to download: " .. url)
    end
    
    local content = response.readAll()
    response.close()
    
    local file = fs.open(path, "w")
    file.write(content)
    file.close()
    
    print("  ✓ " .. path)
end

local function createStartup(scriptPath, machineName)
    print("Creating startup script...")
    
    local startupContent = string.format([[
-- Auto-start script for Casino %s
print("Starting Casino %s...")
shell.run("%s")
]], machineName, machineName, scriptPath)
    
    local file = fs.open("/startup.lua", "w")
    file.write(startupContent)
    file.close()
    
    print("  ✓ /startup.lua")
end

local function installCommon()
    print("Installing common libraries...")
    download(GITHUB_RAW .. "lib/network.lua", "/casino/lib/network.lua")
end

local function installServer()
    print("Installing Central Server...")
    installCommon()
    download(GITHUB_RAW .. "server/server.lua", "/casino/server/server.lua")
    createStartup("/casino/server/server.lua", "Server")
    
    print("\n=== Installation Complete ===")
    print("Start with: /casino/server/server.lua")
    print("Or reboot to auto-start")
    print("\nRequirements:")
    print("- Wired Modem")
    print("- Disk Drive + Floppy Disk")
end

local function installCashier()
    print("Installing Cashier...")
    installCommon()
    download(GITHUB_RAW .. "lib/ui.lua", "/casino/lib/ui.lua")
    download(GITHUB_RAW .. "cashier/cashier.lua", "/casino/cashier/cashier.lua")
    createStartup("/casino/cashier/cashier.lua", "Cashier")
    
    print("\n=== Installation Complete ===")
    print("Start with: /casino/cashier/cashier.lua")
    print("Or reboot to auto-start")
    print("\nRequirements:")
    print("- Wired Modem")
    print("- 5x4 Monitor")
    print("- Inventory Manager + Chest")
    print("- Player Detector")
    print("- Redstone RIGHT (new cards)")
    print("- Redstone BACK (return cards)")
end

local function installGame(gameName)
    print("Installing " .. gameName .. "...")
    installCommon()
    download(GITHUB_RAW .. "lib/ui.lua", "/casino/lib/ui.lua")
    download(GITHUB_RAW .. "games/" .. gameName .. ".lua", "/casino/games/" .. gameName .. ".lua")
    createStartup("/casino/games/" .. gameName .. ".lua", gameName:sub(1,1):upper() .. gameName:sub(2))
    
    print("\n=== Installation Complete ===")
    print("Start with: /casino/games/" .. gameName .. ".lua")
    print("Or reboot to auto-start")
    print("\nRequirements:")
    print("- Wired Modem")
    print("- 5x4 Monitor (touchscreen)")
    print("- Inventory Manager")
    print("- Speaker (optional)")
    print("- Chat Box")
    print("- Redstone BACK (return card)")
end

-- Main installation
print("=== Casino System Installer ===\n")

if machineType == "server" then
    installServer()
elseif machineType == "cashier" then
    installCashier()
elseif machineType == "blackjack" then
    installGame("blackjack")
elseif machineType == "slots" then
    installGame("slots")
elseif machineType == "plinko" then
    installGame("plinko")
else
    print("Invalid machine type: " .. machineType)
    print("Valid types: server, cashier, blackjack, slots, plinko")
end
