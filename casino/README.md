# Minecraft Casino System - ComputerCraft

A complete casino system with Blackjack, Slots, and Plinko games using ComputerCraft and Advanced Peripherals.

## Features

- **Central Server**: Manages all player credits on a floppy disk
- **Cashier System**: Deposit/withdraw diamonds, get player cards
- **Blackjack**: Classic blackjack with standard rules (min: 1, max: 1000)
- **Slots**: 3-reel slots with ~99% RTP (min: 1, max: 100)
- **Plinko**: 16-row plinko with multipliers (min: 5, max: 50)
- **Networked**: All machines communicate via wired modems
- **Notifications**: Toast messages for wins/losses, global chat for big wins (500+)

## Setup Requirements

### Central Server Computer
**Peripherals needed:**
- 1x Wired Modem (any side)
- 1x Disk Drive with Floppy Disk (any side)

**Installation:**
```
cd /
mkdir casino
mkdir casino/lib
mkdir casino/server

-- Copy lib/network.lua to /casino/lib/
-- Copy server/server.lua to /casino/server/

-- Run on startup
/casino/server/server.lua
```

### Cashier Computer
**Peripherals needed:**
- 1x Wired Modem (any side, connected to network)
- 1x Monitor (5x4, any side)
- 1x Inventory Manager (with chest attached for diamond storage)
- 1x Player Detector (Advanced Peripherals)
- Redstone output on RIGHT side (for giving new player cards)
- Redstone output on BACK side (for returning player cards)

**Chest Setup:**
- Attach a chest to the Inventory Manager (NOT to the computer)
- Fill chest with diamonds for withdrawals

**Installation:**
```
cd /
-- Copy lib/network.lua to /casino/lib/
-- Copy cashier/cashier.lua to /casino/cashier/

-- Run on startup
/casino/cashier/cashier.lua
```

### Game Machines (Blackjack, Slots, Plinko)
**Each game machine needs:**
- 1x Computer
- 1x Wired Modem (any side, connected to network)
- 1x Monitor (5x4, any side, touchscreen enabled)
- 1x Inventory Manager (for player card detection)
- 1x Speaker (optional, for sound effects)
- 1x Chat Box (Advanced Peripherals, for notifications)
- Redstone output on BACK side (for returning player cards after game)

**Inventory Manager Setup:**
- A hopper below the Inventory Manager should be locked by redstone
- When BACK redstone activates, it unlocks and drops the player card back
- You need a player to insert their memory card into the Inventory Manager

**Installation for each game:**

**Blackjack:**
```
cd /
-- Copy lib/network.lua and lib/ui.lua to /casino/lib/
-- Copy games/blackjack.lua to /casino/games/

-- Run on startup
/casino/games/blackjack.lua
```

**Slots:**
```
cd /
-- Copy lib/network.lua and lib/ui.lua to /casino/lib/
-- Copy games/slots.lua to /casino/games/

-- Run on startup
/casino/games/slots.lua
```

**Plinko:**
```
cd /
-- Copy lib/network.lua and lib/ui.lua to /casino/lib/
-- Copy games/plinko.lua to /casino/games/

-- Run on startup
/casino/games/plinko.lua
```

## Network Setup

All computers must be connected via **wired modems** using Networking Cables.

1. Place wired modems on all computers
2. Connect them with Networking Cables
3. Right-click modems to open them (they should have a red band when open)

## How to Play

### For Players:

1. **Get a Player Card**:
   - Go to the Cashier
   - Stand within 5 blocks
   - Touch "Get Player Card" on screen
   - You'll receive a Memory Card

2. **Deposit Diamonds**:
   - Insert your Player Card into the Cashier's Inventory Manager
   - Put diamonds in your inventory
   - Touch "Deposit Diamonds"
   - Diamonds are converted 1:1 to credits

3. **Play Games**:
   - Go to any game machine
   - Insert your Player Card into the Inventory Manager
   - The game will load your balance
   - Follow on-screen instructions to play
   - Touch "QUIT" when done to get your card back

4. **Withdraw Credits**:
   - Insert your Player Card at the Cashier
   - Touch "Withdraw Credits"
   - Receive diamonds (1:1 conversion)

### Game Rules:

**Blackjack:**
- Standard rules, dealer stands on 17
- Blackjack pays 3:2
- Min bet: 1, Max bet: 1000

**Slots:**
- 3 reels with 7 symbols
- Payouts: 7-7-7 (500x), D-D-D (100x), B-B-B (50x), etc.
- Touch "PAYOUTS" to see full table
- Min bet: 1, Max bet: 100

**Plinko:**
- Ball drops through 16 rows of pegs
- 18 slots with multipliers from 0.2x to 1000x
- Edge slots have highest multipliers
- Min bet: 5, Max bet: 50

## Win Notifications

- **Regular wins/losses**: Toast notification to player
- **500+ credits**: Global chat announcement
- **Tiers**:
  - 500-999: Nice Win
  - 1000-1999: Great Win
  - 2000-4999: Big Win
  - 5000-9999: Huge Win
  - 10000+: Mega Win

## Troubleshooting

### "No modem found"
- Make sure you have a wired modem attached
- Right-click the modem to open it (red band should appear)

### "No disk in drive"
- Insert a floppy disk into the server's disk drive

### "Request timeout"
- Check network cable connections
- Make sure all modems are open
- Verify the server is running

### Player card not detected
- Make sure the memory card is assigned to the player
- Insert the card into the Inventory Manager (not a chest)

### Game doesn't return card
- Check redstone connection on BACK side
- Verify hopper mechanism is working

## File Structure

```
/casino/
├── lib/
│   ├── network.lua    (Network communication library)
│   └── ui.lua         (UI/Monitor library)
├── server/
│   └── server.lua     (Central server)
├── cashier/
│   └── cashier.lua    (Cashier system)
└── games/
    ├── blackjack.lua  (Blackjack game)
    ├── slots.lua      (Slots game)
    └── plinko.lua     (Plinko game)
```

## Credits System

- All credits are stored in `/disk/players.json`
- Format: `{"username": credits, ...}`
- 1 Diamond = 1 Credit
- All transactions are atomic and synchronized

## Tips

- Keep diamonds stocked in the cashier chest for withdrawals
- Monitor the server computer for transaction logs
- Each game machine can run independently
- You can have multiple instances of each game (just copy the setup)
- Test with small bets first!

---

**Have fun and gamble responsibly!** 🎰🎲🃏
