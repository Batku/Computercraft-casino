-- Casino System Overview
-- Complete file listing and connection diagram

--[[
========================
FILE STRUCTURE
========================

/casino/
├── README.md              - Complete documentation
├── INSTALLATION.md        - Quick setup guide
├── setup.lua             - Interactive setup helper
├── lib/
│   ├── network.lua       - Network communication (rednet)
│   └── ui.lua            - UI/Monitor utilities
├── server/
│   └── server.lua        - Central server (manages player data)
├── cashier/
│   └── cashier.lua       - Cashier system
└── games/
    ├── blackjack.lua     - Blackjack game
    ├── slots.lua         - Slots game
    └── plinko.lua        - Plinko game

========================
CONNECTION REQUIREMENTS
========================

CENTRAL SERVER:
- Computer
- Wired Modem (connected to network)
- Disk Drive + Floppy Disk (any side)

CASHIER:
- Computer
- Wired Modem (connected to network)
- Monitor 5x4 (any side)
- Inventory Manager (any side) → Chest (with diamonds)
- Player Detector (any side)
- Redstone RIGHT side → New card dispenser
- Redstone BACK side → Card return hopper

EACH GAME MACHINE (Blackjack, Slots, Plinko):
- Computer
- Wired Modem (connected to network)
- Monitor 5x4 (any side, must be touchscreen)
- Inventory Manager (any side) → Hopper below (for card insert)
- Speaker (optional, any side)
- Chat Box (any side)
- Redstone BACK side → Hopper unlock (to return card)

========================
CARD MECHANISM DETAILS
========================

Player Card System:
1. Player requests card at cashier
2. Memory Card is dispensed (redstone RIGHT)
3. Player right-clicks Inventory Manager with card to insert it
4. Game detects card via inventoryManager.getOwner()
5. When player quits, redstone BACK activates for 0.5s
6. This unlocks the hopper which drops the card back to player

Suggested Hopper Setup:
- Inventory Manager above hopper
- Hopper locked by redstone torch or similar
- When BACK activates, torch turns off, hopper unlocks briefly
- Card drops through to player collection area

========================
NETWORK PROTOCOL
========================

Request Types:
- "get_balance"      {username: string} → {balance: number}
- "set_balance"      {username: string, balance: number} → {balance: number}
- "add_balance"      {username: string, amount: number} → {balance: number}
- "subtract_balance" {username: string, amount: number} → {balance: number}
- "create_account"   {username: string} → {balance: number}

All communication uses rednet with protocol "casino_network"

========================
DATA STORAGE
========================

File: /disk/players.json
Format: {"username": credits, "username2": credits, ...}
Example: {"Steve": 1000, "Alex": 500}

All values are integers (no decimals)
1 Diamond = 1 Credit

========================
GAME SPECIFICATIONS
========================

BLACKJACK:
- Min bet: 1, Max bet: 1000
- Standard rules
- Dealer stands on 17
- Blackjack pays 3:2
- Push on ties

SLOTS:
- Min bet: 1, Max bet: 100
- 3 reels
- Symbols: 7, Diamond, Bell, Cherry, Lemon, Orange, Plum
- Max payout: 500x (7-7-7)
- RTP: ~99%

PLINKO:
- Min bet: 5, Max bet: 50
- 16 rows of pegs
- 18 slots at bottom
- Multipliers: 1000x, 130x, 26x, 9x, 4x, 2x, 0.2x (mirrored)
- Results rounded down to integer

========================
NOTIFICATION SYSTEM
========================

Toast Notifications (to player):
- All wins and losses
- Format: "won X credits! (Balance: Y)"

Global Chat Announcements (500+ wins):
- 500-999: "NICE WIN"
- 1000-1999: "GREAT WIN" 
- 2000-4999: "BIG WIN"
- 5000-9999: "HUGE WIN"
- 10000+: "MEGA WIN"

========================
STARTUP ORDER
========================

1. Start CENTRAL SERVER first
2. Start CASHIER
3. Start all GAME MACHINES
4. Verify network connectivity
5. Test with one player

========================
TESTING CHECKLIST
========================

□ Server responds to balance requests
□ Cashier can create player cards
□ Cashier can deposit diamonds
□ Cashier can withdraw diamonds
□ Each game detects player cards
□ Each game loads correct balance
□ Each game returns cards on quit
□ Win notifications appear
□ Big wins show in global chat
□ Balance updates persist

========================
TROUBLESHOOTING
========================

"No modem found"
→ Attach wired modem, right-click to open

"Request timeout"
→ Check server is running
→ Verify network cables connected
→ Ensure all modems are open

"No disk in drive"
→ Insert floppy disk into server's drive

Card not detected
→ Right-click Inventory Manager with Memory Card
→ Ensure card is from Advanced Peripherals

Balance not updating
→ Check server is running
→ Verify disk is not full
→ Check network connectivity

Card not returned
→ Check redstone connection on BACK
→ Verify hopper mechanism works
→ Test redstone signal manually

========================
MACHINE LABELS
========================

Recommend labeling each computer:

CASINO-SERVER      (central server)
CASINO-CASHIER     (cashier)
CASINO-BJ-1        (blackjack machine 1)
CASINO-BJ-2        (blackjack machine 2)
CASINO-SLOTS-1     (slots machine 1)
CASINO-SLOTS-2     (slots machine 2)
CASINO-PLINKO-1    (plinko machine 1)
CASINO-PLINKO-2    (plinko machine 2)

Use: label set <name>

========================
PERFORMANCE NOTES
========================

- Server handles multiple simultaneous requests
- Each game runs independently
- Monitor updates are client-side (no network lag)
- Balance updates are synchronized
- No data loss on unexpected shutdown (stored on disk)

========================
SECURITY NOTES
========================

- Players can only access their own balance
- Cannot forge requests (username tied to memory card)
- All transactions logged to server console
- Disk file is human-readable JSON for admin checks
- No credit duplication possible

========================
EXPANSION IDEAS
========================

- Add more game types (roulette, poker, etc.)
- Implement VIP tiers with better payouts
- Add daily/weekly leaderboards
- Create achievement system
- Add progressive jackpots
- Implement house statistics tracking

========================

Created by: batku
For: Minecraft ATM10 Modpack
Using: CC:Tweaked + Advanced Peripherals
Version: 1.0

Good luck with your casino! 🎰

]]--
