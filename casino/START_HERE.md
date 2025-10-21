# 🎰 Minecraft Casino - Complete System Summary

## What I've Built For You

A fully functional casino system with 3 games (Blackjack, Slots, Plinko), central server, and cashier system - all networked together!

## 📁 Files Created

```
/home/batku/Programming/minecraft/casino/
├── README.md                  - Complete documentation
├── INSTALLATION.md            - Quick setup guide  
├── SETUP_DIAGRAMS.md          - Visual diagrams and connection guides
├── SYSTEM_OVERVIEW.lua        - Technical overview
├── setup.lua                  - Interactive setup helper
│
├── lib/
│   ├── network.lua           - Network communication library
│   └── ui.lua                - UI/Monitor utilities library
│
├── server/
│   └── server.lua            - Central server (manages player data on disk)
│
├── cashier/
│   └── cashier.lua           - Cashier (deposits/withdrawals/cards)
│
└── games/
    ├── blackjack.lua         - Blackjack game (min:1, max:1000)
    ├── slots.lua             - Slots game (min:1, max:100)
    └── plinko.lua            - Plinko game (min:5, max:50)
```

## 🎮 Games Summary

| Game      | Min Bet | Max Bet | Special Features                    |
|-----------|---------|---------|-------------------------------------|
| Blackjack | 1       | 1000    | 3:2 blackjack, standard rules       |
| Slots     | 1       | 100     | 500x max, ~99% RTP, 7 symbols       |
| Plinko    | 5       | 50      | 1000x max, 16 rows, edge advantage  |

## 🔌 Connection Requirements Summary

### Central Server (1 machine)
- Computer + Wired Modem + Disk Drive + Floppy Disk

### Cashier (1 machine)  
- Computer + Wired Modem + 5x4 Monitor + Inventory Manager + Chest + Player Detector
- Redstone: RIGHT (new cards), BACK (return cards)

### Game Machines (6 total - 2 of each game)
- Computer + Wired Modem + 5x4 Monitor (touch) + Inventory Manager + Speaker + Chat Box
- Redstone: BACK (return card)

**Total**: 8 computers needed

## ⚠️ CRITICAL Connection Notes

1. **Inventory Manager** must have chest/hopper attached **directly to IT**, not to computer!
   ```
   CORRECT: [Computer] → [Inventory Manager] → [Chest]
   WRONG:   [Computer] → [Chest], [Inventory Manager] (separate)
   ```

2. **Wired Modems** must be used (not wireless) and **opened** (right-click, shows red band)

3. **All machines** must be connected via Networking Cables

4. **Monitor scale** is 0.5 (automatically set) for 5x4 monitors (25 chars × 12 rows)

## 🚀 Quick Start Steps

### In Minecraft:

1. **Build the Central Server first**:
   - Place computer, wired modem, disk drive
   - Insert floppy disk
   - Copy `lib/network.lua` and `server/server.lua` to computer
   - Run `/casino/server/server.lua`
   - Should say "Server ready!"

2. **Build the Cashier**:
   - Place all peripherals
   - Connect chest to Inventory Manager (not computer!)
   - Copy required files
   - Run `/casino/cashier/cashier.lua`

3. **Build 2 Blackjack machines**:
   - Place all peripherals  
   - Set up card return mechanism (hopper + redstone)
   - Copy required files
   - Run `/casino/games/blackjack.lua` on each

4. **Build 2 Slots machines**:
   - Same setup as Blackjack
   - Run `/casino/games/slots.lua` on each

5. **Build 2 Plinko machines**:
   - Same setup as Blackjack
   - Run `/casino/games/plinko.lua` on each

6. **Connect everything** with Networking Cables

7. **Test**:
   - Get player card from cashier
   - Deposit some diamonds  
   - Play a game!

## 📋 What Each File Does

### `lib/network.lua`
- Handles rednet communication between machines
- Implements request/response protocol
- Used by ALL machines (server, cashier, games)

### `lib/ui.lua`  
- Monitor drawing utilities
- Button rendering
- Touch detection
- Used by cashier and all games

### `server/server.lua`
- Listens for network requests
- Manages player balances in `/disk/players.json`
- Handles: get_balance, set_balance, add_balance, subtract_balance, create_account

### `cashier/cashier.lua`
- Deposit diamonds → credits (1:1)
- Withdraw credits → diamonds (1:1)
- Issue new player cards (Memory Cards from Advanced Peripherals)
- Return player cards

### `games/blackjack.lua`
- Classic blackjack with card drawing
- Dealer AI (stands on 17)
- Betting UI with touch controls
- Sound effects and chat notifications

### `games/slots.lua`
- 3-reel slot machine
- Weighted symbol system for ~99% RTP
- Animated spinning
- Payout table viewer

### `games/plinko.lua`
- Physics-based ball drop simulation
- 16 rows of pegs
- Animated drop with sound
- Edge slots have 1000x multiplier!

## 🎯 Player Card System

**Memory Cards** (from Advanced Peripherals) are used to identify players:

1. Player requests card at cashier
2. Card is created and given via redstone (RIGHT)
3. Player right-clicks Inventory Manager to insert card
4. Card is detected via `inventoryManager.getOwner()`
5. When done, redstone (BACK) unlocks hopper to return card

## 💬 Notification System

**Toast Messages** (to individual player):
- Every win/loss shows toast with amount and new balance

**Global Chat** (big wins only):
- 500+: Nice Win 🎉
- 1000+: Great Win 🎊
- 2000+: Big Win 💰
- 5000+: Huge Win 🤑
- 10000+: MEGA WIN 💎

## 🎲 Game Odds & Payouts

### Blackjack
- House edge: ~0.5% (standard blackjack)
- Blackjack pays 3:2 (1.5x your bet)
- Insurance not implemented

### Slots  
- RTP: ~99% (very player-friendly!)
- Symbol weights designed for fair play
- Max win: 50,000 credits (500 bet × 100x max bet × 500x multiplier... wait, max bet is 100, so 50,000)

### Plinko
- RTP: ~99% (due to distribution)
- Most likely: center slots (0.2x - 2x)
- Least likely: edge slots (1000x!)
- Max win: 50,000 credits (50 bet × 1000x)

## 🔧 Troubleshooting Quick Reference

| Problem | Solution |
|---------|----------|
| "No modem found" | Attach wired modem, right-click to open |
| "Request timeout" | Check server running, cables connected |
| "No disk in drive" | Insert floppy disk into server |
| Card not detected | Right-click Inventory Manager with card |
| Card not returned | Check BACK redstone, test hopper unlock |
| Balance not saving | Verify disk not full, server running |

## 📊 Data Storage

**File**: `/disk/players.json` (on server's floppy disk)

**Format**:
```json
{
  "Steve": 1500,
  "Alex": 2300,
  "Herobrine": 999999
}
```

All values are integers (credits). No decimals!

## 🎨 Suggested Decoration

- **Floors**: Red & Black Carpet in checkerboard
- **Walls**: Dark Oak Wood, Crimson Planks
- **Lighting**: Redstone Lamps (always on), Sea Lanterns
- **Accents**: Gold Blocks, Emerald Blocks
- **Signs**: Use item frames with themed items
  - Blackjack: Playing cards (paper with custom names)
  - Slots: Fruit items
  - Plinko: Snowballs or ender pearls

## 📖 Documentation Files

- **README.md** - Full documentation with all features
- **INSTALLATION.md** - Step-by-step setup instructions  
- **SETUP_DIAGRAMS.md** - Visual connection diagrams
- **SYSTEM_OVERVIEW.lua** - Technical details and protocol
- **This file** - Quick summary and overview

## 🎓 How to Copy Files In-Game

You'll need to manually type or paste these into each computer. Here's the easiest method:

### Method 1: Direct File Creation
1. On the computer: `edit /casino/lib/network.lua`
2. Copy contents from this folder's `lib/network.lua`
3. Paste into the editor (Ctrl+V or right-click)
4. Save (Ctrl+S) and exit
5. Repeat for each file

### Method 2: Pastebin (if you have HTTP enabled)
1. Upload each file to pastebin.com
2. Use `pastebin get <code> /casino/lib/network.lua`
3. Repeat for each file

### Method 3: Disk Transfer
1. Create files on one computer
2. Copy to a floppy disk
3. Move disk to other computers
4. Copy from disk to each computer

## ✅ Final Checklist

- [ ] All 8 computers placed and labeled
- [ ] All wired modems attached and opened (red band showing)
- [ ] All networking cables connected
- [ ] Server has disk drive + floppy disk
- [ ] Cashier has chest with diamonds
- [ ] All games have card return mechanism working
- [ ] All files copied to correct locations
- [ ] Server program running (shows "Server ready!")
- [ ] Cashier program running (shows UI)
- [ ] All 6 game programs running (show idle screens)
- [ ] Tested: Get card, deposit, play game, withdraw

## 🎉 You're Ready!

Once everything is set up:
1. Fill cashier chest with diamonds
2. Invite your friends
3. Watch them gamble away their fortunes! 😄

**Good luck with your casino!** 🎰🎲🃏

---

*Created for ATM10 Modpack with CC:Tweaked + Advanced Peripherals*

*Questions? Check README.md for detailed info or SETUP_DIAGRAMS.md for visual guides!*
