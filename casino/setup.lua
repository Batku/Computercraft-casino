-- Startup script generator for casino machines
-- Run this to help set up each machine type

local function clearScreen()
    term.clear()
    term.setCursorPos(1, 1)
end

local function menu()
    clearScreen()
    print("=== Casino Setup Helper ===")
    print("")
    print("What type of machine is this?")
    print("")
    print("1. Central Server")
    print("2. Cashier")
    print("3. Blackjack Game")
    print("4. Slots Game")
    print("5. Plinko Game")
    print("6. Exit")
    print("")
    write("Select (1-6): ")
    
    local choice = read()
    return tonumber(choice)
end

local function createStartup(program)
    local file = fs.open("startup.lua", "w")
    file.write("-- Auto-start casino program\n")
    file.write("shell.run(\"" .. program .. "\")\n")
    file.close()
    
    print("")
    print("Created startup.lua")
    print("This computer will now run:")
    print(program)
    print("")
    print("Restart to test!")
end

local function setupServer()
    clearScreen()
    print("=== Central Server Setup ===")
    print("")
    print("Requirements:")
    print("- Wired modem (any side)")
    print("- Disk drive with floppy disk")
    print("")
    print("Files needed:")
    print("/casino/lib/network.lua")
    print("/casino/server/server.lua")
    print("")
    
    -- Check files
    if not fs.exists("/casino/lib/network.lua") then
        print("ERROR: Missing /casino/lib/network.lua")
        print("Press any key...")
        os.pullEvent("key")
        return
    end
    
    if not fs.exists("/casino/server/server.lua") then
        print("ERROR: Missing /casino/server/server.lua")
        print("Press any key...")
        os.pullEvent("key")
        return
    end
    
    write("Create startup.lua? (y/n): ")
    if read() == "y" then
        createStartup("/casino/server/server.lua")
    end
    
    print("Press any key...")
    os.pullEvent("key")
end

local function setupCashier()
    clearScreen()
    print("=== Cashier Setup ===")
    print("")
    print("Requirements:")
    print("- Wired modem")
    print("- 5x4 Monitor")
    print("- Inventory Manager + Chest")
    print("- Player Detector")
    print("- Redstone: RIGHT (give card)")
    print("- Redstone: BACK (return card)")
    print("")
    print("Files needed:")
    print("/casino/lib/network.lua")
    print("/casino/cashier/cashier.lua")
    print("")
    
    if not fs.exists("/casino/lib/network.lua") then
        print("ERROR: Missing /casino/lib/network.lua")
        print("Press any key...")
        os.pullEvent("key")
        return
    end
    
    if not fs.exists("/casino/cashier/cashier.lua") then
        print("ERROR: Missing /casino/cashier/cashier.lua")
        print("Press any key...")
        os.pullEvent("key")
        return
    end
    
    write("Create startup.lua? (y/n): ")
    if read() == "y" then
        createStartup("/casino/cashier/cashier.lua")
    end
    
    print("Press any key...")
    os.pullEvent("key")
end

local function setupGame(name, file)
    clearScreen()
    print("=== " .. name .. " Setup ===")
    print("")
    print("Requirements:")
    print("- Wired modem")
    print("- 5x4 Monitor (touchscreen)")
    print("- Inventory Manager")
    print("- Speaker (optional)")
    print("- Chat Box")
    print("- Redstone: BACK (return card)")
    print("")
    print("Files needed:")
    print("/casino/lib/network.lua")
    print("/casino/lib/ui.lua")
    print("/casino/games/" .. file)
    print("")
    
    if not fs.exists("/casino/lib/network.lua") then
        print("ERROR: Missing /casino/lib/network.lua")
        print("Press any key...")
        os.pullEvent("key")
        return
    end
    
    if not fs.exists("/casino/lib/ui.lua") then
        print("ERROR: Missing /casino/lib/ui.lua")
        print("Press any key...")
        os.pullEvent("key")
        return
    end
    
    if not fs.exists("/casino/games/" .. file) then
        print("ERROR: Missing /casino/games/" .. file)
        print("Press any key...")
        os.pullEvent("key")
        return
    end
    
    write("Create startup.lua? (y/n): ")
    if read() == "y" then
        createStartup("/casino/games/" .. file)
    end
    
    print("Press any key...")
    os.pullEvent("key")
end

-- Main loop
while true do
    local choice = menu()
    
    if choice == 1 then
        setupServer()
    elseif choice == 2 then
        setupCashier()
    elseif choice == 3 then
        setupGame("Blackjack", "blackjack.lua")
    elseif choice == 4 then
        setupGame("Slots", "slots.lua")
    elseif choice == 5 then
        setupGame("Plinko", "plinko.lua")
    elseif choice == 6 then
        clearScreen()
        print("Setup complete!")
        break
    else
        print("Invalid choice!")
        sleep(1)
    end
end
