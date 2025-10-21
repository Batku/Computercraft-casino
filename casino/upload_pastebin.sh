#!/bin/bash
# Quick setup script to upload all files to pastebin
# Requires: pastebinit (sudo apt install pastebinit)

echo "🎰 Casino System - Pastebin Uploader"
echo "===================================="
echo ""

# Check if pastebinit is installed
if ! command -v pastebinit &> /dev/null; then
    echo "❌ pastebinit not found!"
    echo "Install with: sudo apt install pastebinit"
    echo ""
    echo "Or use the GitHub method instead (see below)"
    exit 1
fi

echo "📤 Uploading files to pastebin..."
echo ""

# Upload library files
echo "📚 Libraries:"
NETWORK_CODE=$(pastebinit -i lib/network.lua -f lua)
echo "  network.lua: $NETWORK_CODE"

UI_CODE=$(pastebinit -i lib/ui.lua -f lua)
echo "  ui.lua: $UI_CODE"

# Upload server
echo ""
echo "🖥️  Server:"
SERVER_CODE=$(pastebinit -i server/server.lua -f lua)
echo "  server.lua: $SERVER_CODE"

# Upload cashier
echo ""
echo "💰 Cashier:"
CASHIER_CODE=$(pastebinit -i cashier/cashier.lua -f lua)
echo "  cashier.lua: $CASHIER_CODE"

# Upload games
echo ""
echo "🎮 Games:"
BLACKJACK_CODE=$(pastebinit -i games/blackjack.lua -f lua)
echo "  blackjack.lua: $BLACKJACK_CODE"

SLOTS_CODE=$(pastebinit -i games/slots.lua -f lua)
echo "  slots.lua: $SLOTS_CODE"

PLINKO_CODE=$(pastebinit -i games/plinko.lua -f lua)
echo "  plinko.lua: $PLINKO_CODE"

echo ""
echo "✅ All files uploaded!"
echo ""
echo "===================================="
echo "📋 Installation Commands:"
echo "===================================="
echo ""
echo "CENTRAL SERVER:"
echo "  mkdir casino && mkdir casino/lib && mkdir casino/server"
echo "  cd /casino/lib && pastebin get $NETWORK_CODE network.lua"
echo "  cd /casino/server && pastebin get $SERVER_CODE server.lua"
echo ""
echo "CASHIER:"
echo "  mkdir casino && mkdir casino/lib && mkdir casino/cashier"
echo "  cd /casino/lib && pastebin get $NETWORK_CODE network.lua"
echo "  cd /casino/cashier && pastebin get $CASHIER_CODE cashier.lua"
echo ""
echo "BLACKJACK:"
echo "  mkdir casino && mkdir casino/lib && mkdir casino/games"
echo "  cd /casino/lib"
echo "  pastebin get $NETWORK_CODE network.lua"
echo "  pastebin get $UI_CODE ui.lua"
echo "  cd /casino/games && pastebin get $BLACKJACK_CODE blackjack.lua"
echo ""
echo "SLOTS:"
echo "  mkdir casino && mkdir casino/lib && mkdir casino/games"
echo "  cd /casino/lib"
echo "  pastebin get $NETWORK_CODE network.lua"
echo "  pastebin get $UI_CODE ui.lua"
echo "  cd /casino/games && pastebin get $SLOTS_CODE slots.lua"
echo ""
echo "PLINKO:"
echo "  mkdir casino && mkdir casino/lib && mkdir casino/games"
echo "  cd /casino/lib"
echo "  pastebin get $NETWORK_CODE network.lua"
echo "  pastebin get $UI_CODE ui.lua"
echo "  cd /casino/games && pastebin get $PLINKO_CODE plinko.lua"
echo ""
echo "===================================="

# Save codes to file
cat > pastebin_codes.txt << EOF
Casino System Pastebin Codes
Generated: $(date)

Libraries:
  network.lua: $NETWORK_CODE
  ui.lua: $UI_CODE

Server:
  server.lua: $SERVER_CODE

Cashier:
  cashier.lua: $CASHIER_CODE

Games:
  blackjack.lua: $BLACKJACK_CODE
  slots.lua: $SLOTS_CODE
  plinko.lua: $PLINKO_CODE
EOF

echo "💾 Codes saved to: pastebin_codes.txt"
