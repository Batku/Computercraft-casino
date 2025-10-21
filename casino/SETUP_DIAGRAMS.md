# Physical Setup Diagrams

## Connection Overview

### **Important: Peripheral Connections**

⚠️ **CRITICAL**: The Inventory Manager must have the chest/hopper attached **directly to it**, NOT to the computer!

```
WRONG:                          CORRECT:
[Computer] ─── [Chest]          [Computer]
    |                               |
[Inv Manager]                  [Inv Manager] ─── [Chest]
```

---

## Central Server Setup

```
                    ┌─────────────────────┐
                    │   CENTRAL SERVER    │
                    │     (Computer)      │
                    └──────────┬──────────┘
                               │
                    ┌──────────┴──────────┐
                    │                     │
             ┌──────▼──────┐      ┌──────▼──────┐
             │ Wired Modem │      │ Disk Drive  │
             │  (Network)  │      │  + Floppy   │
             └─────────────┘      └─────────────┘
                    │
                    │ Networking Cable
                    ▼
            (To other machines)
```

**Program**: `/casino/server/server.lua`

**Console Output**:
```
Casino Server Starting...
Disk drive found
Network initialized
Server ready!
Listening for requests...
```

---

## Cashier Setup

```
                    ┌─────────────────────┐
                    │   CASHIER COMPUTER  │
                    └──┬──┬───┬───┬───┬───┘
                       │  │   │   │   │
        ┌──────────────┘  │   │   │   └─────────────┐
        │                 │   │   │                 │
┌───────▼────────┐  ┌─────▼───▼───▼──────┐  ┌──────▼──────┐
│ Player Detector│  │    5x4 Monitor     │  │Wired Modem  │
│(Range: 5 blocks│  │   (Touchscreen)    │  │ (Network)   │
└────────────────┘  └────────────────────┘  └─────────────┘
                             
        ┌────────────────────────────────┐
        │     Inventory Manager          │
        └────────────┬───────────────────┘
                     │
              ┌──────▼──────┐
              │    Chest    │
              │  (Diamonds) │
              └─────────────┘

Redstone Outputs:
├─ RIGHT: Dispenser (new cards) ─┐
│                                 │
│  ┌──────────────────────────┐  │
│  │[Memory Card] [Memory Card]│◄─┘
│  │   Dispenser               │
│  └───────────────────────────┘
│
└─ BACK: Hopper unlock ──┐
                          │
   ┌──────────────────────▼───┐
   │  Locked Hopper           │
   │  (Unlocks when signal)   │
   └──────────────────────────┘
```

**Program**: `/casino/cashier/cashier.lua`

**Touch Buttons**:
1. Deposit Diamonds (y=4)
2. Withdraw Credits (y=5)
3. Get Player Card (y=6)
4. Return Player Card (y=7)

---

## Game Machine Setup (All Games)

```
                    ┌─────────────────────┐
                    │   GAME COMPUTER     │
                    │  (Blackjack/Slots/  │
                    │      Plinko)        │
                    └──┬──┬───┬───┬───────┘
                       │  │   │   │
        ┌──────────────┘  │   │   └──────────────┐
        │                 │   │                  │
┌───────▼────────┐  ┌─────▼───▼──────┐   ┌──────▼──────┐
│   Chat Box     │  │  5x4 Monitor   │   │Wired Modem  │
│ (Notifications)│  │ (Touchscreen)  │   │ (Network)   │
└────────────────┘  └────────────────┘   └─────────────┘

        ┌────────────────────┐      ┌─────────────┐
        │ Inventory Manager  │      │  Speaker    │
        └──────────┬─────────┘      │  (Optional) │
                   │                └─────────────┘
            ┌──────▼──────┐
            │   Hopper    │◄─── Redstone BACK
            │  (Locked)   │     (Unlocks to return card)
            └──────┬──────┘
                   │
            ┢━━━━━━▼━━━━━━┪
            ┃   Player    ┃
            ┃  Collects   ┃
            ┃  Card Here  ┃
            ┗━━━━━━━━━━━━━┛
```

**Programs**:
- Blackjack: `/casino/games/blackjack.lua`
- Slots: `/casino/games/slots.lua`
- Plinko: `/casino/games/plinko.lua`

---

## Card Return Mechanism (Detailed)

### Option 1: Simple Hopper Drop

```
[Inventory Manager]
        │
   [  Hopper  ]  ◄─── Locked by redstone torch
        │
   [ Air Gap ]
        │
    Player ↓ (picks up card)
```

**Redstone Circuit**:
```
Computer BACK ──┐
                │
         ┌──────▼──────┐
         │ Redstone    │
         │ Repeater    │
         └──────┬──────┘
                │
         ┌──────▼──────┐
         │ Redstone    │
         │ Torch       │
         │ (inverted)  │
         └──────┬──────┘
                │
            [Hopper]
            
When BACK activates:
1. Signal goes HIGH
2. Torch turns OFF
3. Hopper unlocks
4. Card drops
5. After 0.5s, signal goes LOW
6. Torch turns ON
7. Hopper locks again
```

### Option 2: Dropper System

```
[Inventory Manager]
        │
   [ Dropper ]  ◄─── Activated by BACK redstone
        │
    Player ↓ (catches card in inventory)
```

---

## Network Layout Example

```
                    ╔═══════════════════╗
                    ║  CENTRAL SERVER   ║
                    ╚═════════╦═════════╝
                              ║
                    ┌─────────╨─────────┐
                    │  Network Cable    │
                    └─────────┬─────────┘
              ┌───────────────┼───────────────┐
              │               │               │
        ┌─────▼─────┐   ┌─────▼─────┐   ┌────▼──────┐
        │  CASHIER  │   │Blackjack 1│   │  Slots 1  │
        └───────────┘   └───────────┘   └───────────┘
                              │               │
                    ┌─────────┴───────────────┘
                    │
          ┌─────────┼─────────┬─────────┐
          │         │         │         │
    ┌─────▼─────┬───▼────┬────▼────┬────▼─────┐
    │Blackjack 2│Slots 2 │Plinko 1 │Plinko 2  │
    └───────────┴────────┴─────────┴──────────┘
```

**Cable Requirements**:
- Use Networking Cables (from ComputerCraft)
- Right-click wired modems to open them
- Red band on modem = open
- All machines must be on same network

---

## Player Flow Diagram

```
┌─────────────┐
│   PLAYER    │
│   ARRIVES   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   CASHIER   │
│ Get Card    │◄─── Touch "Get Player Card"
└──────┬──────┘
       │ Receives Memory Card
       ▼
┌─────────────┐
│   CASHIER   │
│   Deposit   │◄─── Put diamonds in inventory
│  Diamonds   │     Touch "Deposit Diamonds"
└──────┬──────┘
       │ Credits added to account
       ▼
┌─────────────┐
│ GAME MACHINE│
│Insert Card  │◄─── Right-click Inv Manager with card
└──────┬──────┘
       │
       ▼
┌─────────────┐
│    PLAY!    │
│  Bet & Win  │◄─── Touch screen to play
└──────┬──────┘
       │
       ▼
┌─────────────┐
│ Touch QUIT  │
│Return Card  │◄─── Card drops from hopper
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   CASHIER   │
│  Withdraw   │◄─── Touch "Withdraw Credits"
│  Diamonds   │     Receive diamonds
└──────┬──────┘
       │
       ▼
┌─────────────┐
│Return Card  │◄─── Touch "Return Player Card"
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   DONE!     │
└─────────────┘
```

---

## Build Checklist

### Central Server
- [ ] Computer placed
- [ ] Wired modem attached and opened
- [ ] Disk drive attached
- [ ] Floppy disk inserted
- [ ] Files copied
- [ ] Program running
- [ ] Console shows "Server ready!"

### Cashier
- [ ] Computer placed
- [ ] Wired modem attached and opened
- [ ] Monitor attached (5x4)
- [ ] Inventory Manager placed
- [ ] Chest attached to Inventory Manager
- [ ] Chest filled with diamonds
- [ ] Player Detector attached
- [ ] Redstone RIGHT → Card dispenser
- [ ] Redstone BACK → Hopper unlock
- [ ] Files copied
- [ ] Program running

### Each Game Machine (x6 total)
- [ ] Computer placed
- [ ] Wired modem attached and opened
- [ ] Monitor attached (5x4, touchscreen)
- [ ] Inventory Manager placed
- [ ] Hopper below Inventory Manager
- [ ] Hopper lock mechanism working
- [ ] Redstone BACK → Hopper unlock
- [ ] Speaker attached (optional)
- [ ] Chat Box attached
- [ ] Files copied
- [ ] Program running
- [ ] Idle screen showing

### Network
- [ ] All modems connected with cables
- [ ] All modems opened (red band)
- [ ] Test request from game to server

---

## Decoration Ideas

```
    ╔═══════════════════════════════════╗
    ║         CASINO ENTRANCE           ║
    ╚═══════════════════════════════════╝
                    │
    ┌───────────────┴───────────────┐
    │                               │
┌───▼────┐                    ┌─────▼───┐
│CASHIER │                    │  GAMES  │
│ BOOTH  │                    │  FLOOR  │
└────────┘                    └─────────┘
                                   │
                   ┌───────────────┼───────────────┐
                   │               │               │
            ┌──────▼──────┐ ┌──────▼──────┐ ┌──────▼──────┐
            │  BLACKJACK  │ │    SLOTS    │ │   PLINKO    │
            │   Area      │ │    Area     │ │    Area     │
            │  [BJ1][BJ2] │ │ [SL1] [SL2] │ │ [PL1] [PL2] │
            └─────────────┘ └─────────────┘ └─────────────┘
```

**Suggested Blocks**:
- Floors: Polished Blackstone, Red/Black Carpet
- Walls: Dark Oak, Crimson Planks
- Lighting: Redstone Lamps, Sea Lanterns
- Accents: Gold Blocks, Emerald Blocks
- Signs: Item Frames with game items

---

**Ready to build? Start with the Central Server!**
