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
    echo "[✗] GitHub repository URL required."
    exit 1
fi

DIR="$TOOLS/$NAME"
REPO="$DIR/repo"

mkdir -p "$DIR"

echo
echo "[*] Adding: $NAME"
echo "[*] URL: $URL"
echo

if [ -d "$REPO/.git" ]; then
    echo "[*] Updating..."
    git -C "$REPO" pull --ff-only || true
else
    echo "[*] Cloning..."
    git clone "$URL" "$REPO"
fi

find "$REPO" -type f \
    \( -name "*.sh" -o -name "*.py" \) \
    -exec chmod +x {} \; 2>/dev/null || true

if [ -f "$REPO/requirements.txt" ]; then
    echo "[*] Installing Python dependencies..."
    python -m pip install -r "$REPO/requirements.txt" || true
fi

if [ -f "$REPO/package.json" ]; then

    if ! command -v node >/dev/null 2>&1; then
        pkg install -y nodejs
    fi

    echo "[*] Installing Node dependencies..."

    (
        cd "$REPO"
        npm install
    ) || true

fi

cat > "$BIN/$NAME" <<KRISHN_COMMAND
#!/data/data/com.termux/files/usr/bin/bash

REPO="$REPO"

cd "\$REPO"

if [ -f main.py ]; then
    exec python main.py

elif [ -f "$NAME.py" ]; then
    exec python "$NAME.py"

elif [ -f main.sh ]; then
    exec bash main.sh

elif [ -f run.sh ]; then
    exec bash run.sh

else
    echo "[!] Launcher not detected."
    echo
    find . -maxdepth 2 -type f | head -50
fi
KRISHN_COMMAND

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