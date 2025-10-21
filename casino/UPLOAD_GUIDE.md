# File Upload Guide

## 🎯 Recommended: GitHub Method

### Step 1: Create GitHub Repository

```bash
cd /home/batku/Programming/minecraft/casino
git init
git add .
git commit -m "Initial casino system"
git branch -M main
git remote add origin https://github.com/YOUR_USERNAME/mc-casino.git
git push -u origin main
```

### Step 2: In Minecraft (on each computer)

**For Central Server:**
```lua
-- Enable HTTP API in config/computercraft-server.toml if needed
-- Then run these commands:

mkdir casino
mkdir casino/lib
mkdir casino/server

wget https://raw.githubusercontent.com/YOUR_USERNAME/mc-casino/main/lib/network.lua /casino/lib/network.lua
wget https://raw.githubusercontent.com/YOUR_USERNAME/mc-casino/main/server/server.lua /casino/server/server.lua

-- Start server
/casino/server/server.lua
```

**For Cashier:**
```lua
mkdir casino
mkdir casino/lib
mkdir casino/cashier

wget https://raw.githubusercontent.com/YOUR_USERNAME/mc-casino/main/lib/network.lua /casino/lib/network.lua
wget https://raw.githubusercontent.com/YOUR_USERNAME/mc-casino/main/cashier/cashier.lua /casino/cashier/cashier.lua

-- Start cashier
/casino/cashier/cashier.lua
```

**For Each Game:**
```lua
mkdir casino
mkdir casino/lib
mkdir casino/games

wget https://raw.githubusercontent.com/YOUR_USERNAME/mc-casino/main/lib/network.lua /casino/lib/network.lua
wget https://raw.githubusercontent.com/YOUR_USERNAME/mc-casino/main/lib/ui.lua /casino/lib/ui.lua

-- For Blackjack:
wget https://raw.githubusercontent.com/YOUR_USERNAME/mc-casino/main/games/blackjack.lua /casino/games/blackjack.lua
/casino/games/blackjack.lua

-- For Slots:
wget https://raw.githubusercontent.com/YOUR_USERNAME/mc-casino/main/games/slots.lua /casino/games/slots.lua
/casino/games/slots.lua

-- For Plinko:
wget https://raw.githubusercontent.com/YOUR_USERNAME/mc-casino/main/games/plinko.lua /casino/games/plinko.lua
/casino/games/plinko.lua
```

---

## 🌐 Alternative: Pastebin Method

### Step 1: Upload to Pastebin

**Linux (with pastebinit):**
```bash
chmod +x upload_pastebin.sh
./upload_pastebin.sh
```

**Manual upload:**
1. Go to pastebin.com
2. Paste each file's contents
3. Set syntax to "Lua"
4. Click "Create New Paste"
5. Note the code (e.g., "ABC123")

### Step 2: In Minecraft

```lua
-- Example for server:
mkdir casino && mkdir casino/lib && mkdir casino/server
cd /casino/lib && pastebin get ABC123 network.lua
cd /casino/server && pastebin get XYZ789 server.lua
```

---

## 💾 Alternative: Disk Transfer Method

### Step 1: Set up on one computer
1. Manually type/paste all files on one computer
2. Verify they work

### Step 2: Copy to floppy disk
```lua
cp /casino/lib/network.lua /disk/network.lua
cp /casino/lib/ui.lua /disk/ui.lua
-- etc.
```

### Step 3: Move disk to other computers
```lua
-- On each new computer:
mkdir casino/lib
cp /disk/network.lua /casino/lib/network.lua
-- etc.
```

---

## 🚀 Best Practice: Use the Installer!

### Step 1: Upload installer.lua to pastebin
1. Upload `installer.lua` to pastebin
2. Get the code (e.g., "INSTALL1")

### Step 2: On each computer in Minecraft

**AFTER you've created the GitHub repo:**

```lua
-- Edit installer.lua to replace YOUR_USERNAME
-- Then upload to pastebin and use:

pastebin get INSTALL1 installer.lua

-- For server:
installer.lua server

-- For cashier:
installer.lua cashier

-- For games:
installer.lua blackjack
installer.lua slots
installer.lua plinko
```

This downloads everything automatically! 🎉

---

## 🔧 Enable HTTP API (if needed)

If `wget` or `pastebin` don't work, edit your server config:

**File:** `config/computercraft-server.toml`

```toml
[http]
    enabled = true
    
    [[http.rules]]
        host = "*"
        action = "allow"
```

Then restart the server.

---

## 📝 Quick Git Setup Commands

```bash
# In the casino directory:
cd /home/batku/Programming/minecraft/casino

# Initialize git
git init

# Add all files
git add .

# Commit
git commit -m "Minecraft Casino System - Blackjack, Slots, Plinko"

# Create repo on GitHub, then:
git remote add origin https://github.com/YOUR_USERNAME/mc-casino.git
git branch -M main
git push -u origin main
```

### Add a .gitignore

```gitignore
# Ignore test files
test_*.lua

# Ignore backup files
*.bak
*~

# Ignore OS files
.DS_Store
Thumbs.db
```

---

## 🎯 Recommended Approach

**For your use case, I recommend:**

1. **Create GitHub repo** (easiest to update later)
2. **Use wget in-game** to download files
3. **Create startup.lua files** on each computer to auto-run

**Why GitHub?**
- ✅ Easy to update files
- ✅ Players can download updates
- ✅ Version control
- ✅ Free and reliable
- ✅ No character limits (pastebin has limits)

**Example workflow:**
1. Make changes on your PC
2. `git push` to GitHub
3. In Minecraft: re-run wget commands
4. Restart computers

---

## 📊 Comparison

| Method | Pros | Cons |
|--------|------|------|
| **GitHub + wget** | Easy updates, version control, unlimited size | Requires HTTP API |
| **Pastebin** | Traditional CC method, simple | File size limits, harder to update |
| **Disk transfer** | No internet needed | Tedious, error-prone |
| **Manual typing** | No dependencies | Very tedious! |

---

## 🎬 Quick Start (Using GitHub)

```bash
# 1. On your PC
cd /home/batku/Programming/minecraft/casino
git init
git add .
git commit -m "Initial commit"
# Create repo on GitHub
git remote add origin https://github.com/batku/mc-casino.git
git push -u origin main

# 2. In Minecraft (Central Server)
mkdir casino/lib -p && mkdir casino/server
cd /casino/lib
wget https://raw.githubusercontent.com/batku/mc-casino/main/lib/network.lua
cd /casino/server  
wget https://raw.githubusercontent.com/batku/mc-casino/main/server/server.lua
/casino/server/server.lua

# 3. Repeat for other machines...
```

That's it! 🎰

---

**Need help? Let me know which method you prefer and I can give more specific instructions!**
