# Quick Installation Guide

## Step 1: Copy Files to Each Computer

You'll need to manually copy the files to each ComputerCraft computer in-game.

### For the Central Server:
1. Create directories:
   ```
   mkdir casino
   mkdir casino/lib
   mkdir casino/server
   ```

2. Create `/casino/lib/network.lua` (copy from lib/network.lua)
3. Create `/casino/server/server.lua` (copy from server/server.lua)

### For the Cashier:
1. Create directories:
   ```
   mkdir casino
   mkdir casino/lib
   mkdir casino/cashier
   ```

2. Create `/casino/lib/network.lua` (copy from lib/network.lua)
3. Create `/casino/cashier/cashier.lua` (copy from cashier/cashier.lua)

### For Each Game Machine:
1. Create directories:
   ```
   mkdir casino
   mkdir casino/lib
   mkdir casino/games
   ```

2. Create `/casino/lib/network.lua` (copy from lib/network.lua)
3. Create `/casino/lib/ui.lua` (copy from lib/ui.lua)
4. Create the appropriate game file:
   - Blackjack: `/casino/games/blackjack.lua`
   - Slots: `/casino/games/slots.lua`
   - Plinko: `/casino/games/plinko.lua`

## Step 2: Hardware Setup

### Central Server:
```
[Computer]
  ├─ [Wired Modem] (any side)
  └─ [Disk Drive with Floppy Disk] (any side)
```

### Cashier:
```
[Computer]
  ├─ [Wired Modem] (any side, networked)
  ├─ [Monitor 5x4] (any side)
  ├─ [Player Detector] (any side)
  ├─ [Inventory Manager] ─── [Chest with Diamonds]
  ├─ RIGHT: Redstone (to dispenser with memory cards)
  └─ BACK: Redstone (to hopper unlock mechanism)
```

### Game Machines (all 3 types):
```
[Computer]
  ├─ [Wired Modem] (any side, networked)
  ├─ [Monitor 5x4 Touchscreen] (any side)
  ├─ [Inventory Manager] ─── [Hopper for card return]
  ├─ [Speaker] (optional, any side)
  ├─ [Chat Box] (any side)
  └─ BACK: Redstone (to hopper unlock)
```

## Step 3: Network Connections

1. Place Networking Cables between all computers
2. Right-click each wired modem to open it (should show red band)
3. Verify all modems are connected to the same network

## Step 4: Start Programs

### Option A - Manual Start:
On each computer, run:
```
/casino/server/server.lua     (for server)
/casino/cashier/cashier.lua   (for cashier)
/casino/games/blackjack.lua   (for blackjack)
/casino/games/slots.lua       (for slots)
/casino/games/plinko.lua      (for plinko)
```

### Option B - Auto-Start:
Create a `startup.lua` file on each computer:

**Server startup.lua:**
```lua
shell.run("/casino/server/server.lua")
```

**Cashier startup.lua:**
```lua
shell.run("/casino/cashier/cashier.lua")
```

**Game startup.lua:**
```lua
shell.run("/casino/games/blackjack.lua")  -- or slots.lua or plinko.lua
```

Then restart each computer (Ctrl+R)

## Step 5: Testing

1. **Start the server first** - it should say "Server ready! Listening for requests..."

2. **Start the cashier** - it should say "Ready! Insert player card or select option"

3. **Get a player card**:
   - Stand near the cashier
   - Touch "Get Player Card"
   - You should receive a Memory Card

4. **Deposit diamonds**:
   - Put diamonds in your inventory
   - Right-click the Inventory Manager with your Memory Card
   - Touch "Deposit Diamonds" on the cashier screen

5. **Test a game**:
   - Start a game machine
   - Insert your Memory Card into its Inventory Manager
   - The game should load and show your balance
   - Play a round!

## Troubleshooting

### Network Issues:
- Verify all modems are open (red band visible)
- Check cables are connected
- Make sure server is running first

### Peripheral Issues:
- Use `peripherals` command to list connected peripherals
- Verify Advanced Peripherals mod is installed
- Check peripheral placement (Inventory Manager needs chest attached to IT, not computer)

### Card Issues:
- Memory Cards must be from Advanced Peripherals
- Insert card into Inventory Manager by right-clicking
- One card per Inventory Manager

## Physical Layout Suggestion

```
        [Network Cable Line]
              |
    ┌─────────┼─────────┬─────────┬─────────┐
    |         |         |         |         |
[Server]  [Cashier] [Black-  [Slots-1] [Plinko-
                     jack-1]             1]
                        
                        |
              ┌─────────┼─────────┐
              |         |         |
          [Black-   [Slots-2] [Plinko-
           jack-2]              2]
```

## Game Settings Summary

| Game      | Min Bet | Max Bet | Special Rules              |
|-----------|---------|---------|----------------------------|
| Blackjack | 1       | 1000    | 3:2 on blackjack          |
| Slots     | 1       | 100     | 500x max multiplier       |
| Plinko    | 5       | 50      | 1000x max multiplier      |

## Next Steps

Once everything is working:
1. Stock the cashier chest with diamonds
2. Decorate the casino area
3. Create signs with game instructions
4. Set up a comfortable waiting area
5. Invite players!

Enjoy your casino! 🎰
