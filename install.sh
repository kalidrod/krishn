#!/data/data/com.termux/files/usr/bin/bash

set -e

OWNER="KRISHN"
APP="krishn-tools"
BASE="$HOME/.krishn-tools"
TOOLS="$BASE/tools"
BIN="$PREFIX/bin"

clear

echo "╔══════════════════════════════════════╗"
echo "║          K R I S H N  T O O L S     ║"
echo "║            INSTALLER v1.0            ║"
echo "║              OWNER: $OWNER             ║"
echo "╚══════════════════════════════════════╝"
echo

if [ -z "$PREFIX" ]; then
    echo "[✗] This installer is for Termux."
    exit 1
fi

echo "[*] Setting up..."

pkg update -y
pkg install -y git bash curl python dpkg

mkdir -p "$TOOLS"
mkdir -p "$BIN"

# Main tool manager
cat > "$BIN/krishn-tools" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

BASE="$HOME/.krishn-tools"
TOOLS="$BASE/tools"

echo
echo "╔══════════════════════════════════════╗"
echo "║            KRISHN TOOLS              ║"
echo "╚══════════════════════════════════════╝"
echo

FOUND=0

for DIR in "$TOOLS"/*; do
    [ -d "$DIR" ] || continue

    NAME="$(basename "$DIR")"
    FOUND=1

    echo "  • $NAME"
done

if [ "$FOUND" = "0" ]; then
    echo "No tools installed."
    echo
    echo "Use:"
    echo "  add.sh <name> <github-url>"
fi

echo
EOF

chmod +x "$BIN/krishn-tools"

# ADD.SH
cat > "$BIN/add.sh" <<'EOF'
#!/data/data/com.termux/files/usr/bin/bash

set -e

BASE="$HOME/.krishn-tools"
TOOLS="$BASE/tools"
BIN="$PREFIX/bin"

if [ "$#" -lt 2 ]; then
    echo
    echo "╔══════════════════════════════════════╗"
    echo "║          KRISHN TOOL ADDER           ║"
    echo "╚══════════════════════════════════════╝"
    echo
    echo "Usage:"
    echo
    echo "  add.sh <tool-name> <github-url>"
    echo
    echo "Example:"
    echo "  add.sh digai https://github.com/Krishn-145/DIGAI.git"
    echo
    exit 1
fi

NAME="$1"
URL="$2"

if ! [[ "$NAME" =~ ^[a-zA-Z0-9_-]+$ ]]; then
    echo "[✗] Invalid tool name."
    exit 1
fi

if [[ "$URL" != https://github.com/* ]]; then
    echo "[✗] Only GitHub repository URLs are supported."
    exit 1
fi

DIR="$TOOLS/$NAME"
REPO="$DIR/repo"

mkdir -p "$DIR"

echo
echo "[*] Adding $NAME..."
echo "[*] Repository: $URL"
echo

if [ -d "$REPO/.git" ]; then
    echo "[*] Updating existing repository..."
    git -C "$REPO" pull --ff-only || true
else
    echo "[*] Downloading repository..."
    rm -rf "$REPO"
    git clone "$URL" "$REPO"
fi

# Basic permissions
find "$REPO" -type f \
    \( -name "*.sh" -o -name "*.py" \) \
    -exec chmod +x {} \; 2>/dev/null || true

# Basic Python dependency support
if [ -f "$REPO/requirements.txt" ]; then
    echo "[*] Installing Python dependencies..."
    python -m pip install -r "$REPO/requirements.txt" || {
        echo "[!] Some Python dependencies could not be installed."
    }
fi

# Basic Node dependency support
if [ -f "$REPO/package.json" ]; then
    if ! command -v node >/dev/null 2>&1; then
        pkg install -y nodejs
    fi

    echo "[*] Installing Node dependencies..."
    (
        cd "$REPO"
        npm install
    ) || {
        echo "[!] Node dependencies could not be installed."
    }
fi

# Create command
cat > "$BIN/$NAME" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

REPO="$REPO"

if [ ! -d "\$REPO" ]; then
    echo "[✗] Tool repository not found."
    exit 1
fi

cd "\$REPO"

echo
echo "======================================"
echo " KRISHN TOOLS : $NAME"
echo "======================================"
echo

if [ -f main.py ]; then
    exec python main.py
elif [ -f "$NAME.py" ]; then
    exec python "$NAME.py"
elif [ -f main.sh ]; then
    exec bash main.sh
elif [ -f run.sh ]; then
    exec bash run.sh
else
    echo "[!] Automatic launcher not found."
    echo
    echo "Repository:"
    echo "\$REPO"
    echo
    echo "Available files:"
    find . -maxdepth 2 -type f | head -50
fi
EOF

chmod +x "$BIN/$NAME"

echo
echo "╔══════════════════════════════════════╗"
echo "║          TOOL ADDED SUCCESSFULLY     ║"
echo "╚══════════════════════════════════════╝"
echo
echo "Tool    : $NAME"
echo "Command : $NAME"
echo
echo "Run:"
echo "  $NAME"
echo
EOF

chmod +x "$BIN/add.sh"

echo
echo "[✓] Installation complete."
echo
echo "Owner : $OWNER"
echo "Path  : $BASE"
echo
echo "Tool manager:"
echo "  krishn-tools"
echo
echo "Add a tool:"
echo "  add.sh <name> <github-url>"
echo
echo "Example:"
echo "  add.sh digai https://github.com/Krishn-145/DIGAI.git"
echo
echo "Then run:"
echo "  digai"
echo
