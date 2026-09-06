#!/data/data/com.termux/files/usr/bin/bash

set -e

OWNER="KRISHN"
VERSION="1.0.0"

BASE="$HOME/.krishn-tools"
TOOLS="$BASE/tools"
BIN="$PREFIX/bin"

clear

echo "╔══════════════════════════════════════╗"
echo "║          K R I S H N  T O O L S     ║"
echo "║              v$VERSION               ║"
echo "║            OWNER: $OWNER             ║"
echo "╚══════════════════════════════════════╝"
echo

if [ -z "$PREFIX" ]; then
    echo "[✗] This installer must run inside Termux."
    exit 1
fi

echo "[*] Installing required packages..."

pkg update -y
pkg install -y git bash curl python

mkdir -p "$TOOLS"
mkdir -p "$BIN"

# --------------------------------------------------
# KRISHN-TOOLS COMMAND
# --------------------------------------------------

cat > "$BIN/krishn-tools" <<'KRISHN_MANAGER'
#!/data/data/com.termux/files/usr/bin/bash

BASE="$HOME/.krishn-tools"
TOOLS="$BASE/tools"

echo
echo "╔══════════════════════════════════════╗"
echo "║            KRISHN TOOLS              ║"
echo "╚══════════════════════════════════════╝"
echo

COUNT=0

for DIR in "$TOOLS"/*; do
    if [ -d "$DIR" ]; then
        NAME="$(basename "$DIR")"
        echo "  [✓] $NAME"
        COUNT=$((COUNT + 1))
    fi
done

if [ "$COUNT" -eq 0 ]; then
    echo "  No tools installed."
fi

echo
echo "Total tools: $COUNT"
echo
echo "Add tool:"
echo "  add.sh <name> <github-url>"
echo
KRISHN_MANAGER

chmod +x "$BIN/krishn-tools"

# --------------------------------------------------
# ADD.SH COMMAND
# --------------------------------------------------

cat > "$BIN/add.sh" <<'KRISHN_ADD'
#!/data/data/com.termux/files/usr/bin/bash

set -e

BASE="$HOME/.krishn-tools"
TOOLS="$BASE/tools"
BIN="$PREFIX/bin"

if [ "$#" -ne 2 ]; then
    echo
    echo "╔══════════════════════════════════════╗"
    echo "║          KRISHN TOOL ADDER           ║"
    echo "╚══════════════════════════════════════╝"
    echo
    echo "Usage:"
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
    echo "[✗] Only GitHub repositories are supported."
    exit 1
fi

DIR="$TOOLS/$NAME"
REPO="$DIR/repo"

echo
echo "╔══════════════════════════════════════╗"
echo "║          KRISHN TOOL ADDER           ║"
echo "╚══════════════════════════════════════╝"
echo
echo "Tool : $NAME"
echo "URL  : $URL"
echo

mkdir -p "$DIR"

if [ -d "$REPO/.git" ]; then

    echo "[*] Tool already exists."
    echo "[*] Updating repository..."

    if ! git -C "$REPO" pull --ff-only; then
        echo "[!] Update failed. Existing version will be used."
    fi

else

    echo "[*] Downloading repository..."

    rm -rf "$REPO"

    git clone "$URL" "$REPO"

fi

echo "[✓] Repository ready."

# --------------------------------------------------
# PERMISSIONS
# --------------------------------------------------

find "$REPO" -type f \
    \( -name "*.sh" -o -name "*.py" \) \
    -exec chmod +x {} \; 2>/dev/null || true

# --------------------------------------------------
# PYTHON DEPENDENCIES
# --------------------------------------------------

if [ -f "$REPO/requirements.txt" ]; then

    echo
    echo "[*] requirements.txt detected."
    echo "[*] Installing Python dependencies..."

    python -m pip install -r "$REPO/requirements.txt" || {
        echo "[!] Some Python dependencies could not be installed."
    }

fi

# --------------------------------------------------
# NODE DEPENDENCIES
# --------------------------------------------------

if [ -f "$REPO/package.json" ]; then

    echo
    echo "[*] package.json detected."

    if ! command -v node >/dev/null 2>&1; then
        echo "[*] Installing Node.js..."
        pkg install -y nodejs
    fi

    echo "[*] Installing Node dependencies..."

    (
        cd "$REPO"
        npm install
    ) || {
        echo "[!] Some Node dependencies could not be installed."
    }

fi

# --------------------------------------------------
# CREATE TOOL COMMAND
# --------------------------------------------------

cat > "$BIN/$NAME" <<KRISHN_LAUNCHER
#!/data/data/com.termux/files/usr/bin/bash

REPO="$REPO"

if [ ! -d "\$REPO" ]; then
    echo "[✗] Tool repository not found."
    exit 1
fi

cd "\$REPO"

echo
echo "======================================"
echo " KRISHN TOOLS"
echo " TOOL: $NAME"
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
    echo "[!] Automatic launcher was not detected."
    echo
    echo "Repository:"
    echo "\$REPO"
    echo
    echo "Available files:"
    find . -maxdepth 2 -type f | head -50
fi
KRISHN_LAUNCHER

chmod +x "$BIN/$NAME"

echo
echo "╔══════════════════════════════════════╗"
echo "║       TOOL ADDED SUCCESSFULLY        ║"
echo "╚══════════════════════════════════════╝"
echo
echo "Tool    : $NAME"
echo "Command : $NAME"
echo
echo "Run:"
echo "  $NAME"
echo
KRISHN_ADD

chmod +x "$BIN/add.sh"

# --------------------------------------------------
# FINISH
# --------------------------------------------------

echo
echo "╔══════════════════════════════════════╗"
echo "║       INSTALLATION COMPLETE          ║"
echo "╚══════════════════════════════════════╝"
echo
echo "Owner: $OWNER"
echo
echo "Commands installed:"
echo "  krishn-tools"
echo "  add.sh"
echo
echo "Example:"
echo "  add.sh digai https://github.com/Krishn-145/DIGAI.git"
echo
echo "[✓] KRISHN Tools Manager is ready."