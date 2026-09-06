#!/data/data/com.termux/files/usr/bin/bash

set -e

BASE="$HOME/.krishn-tools"
TOOLS="$BASE/tools"
BIN="$PREFIX/bin"

if [ "$#" -lt 2 ]; then
    echo "Usage: add.sh <tool-name> <github-url>"
    echo
    echo "Example:"
    echo "add.sh digai https://github.com/Krishn-145/DIGAI.git"
    exit 1
fi

NAME="$1"
URL="$2"

DIR="$TOOLS/$NAME"
REPO="$DIR/repo"

mkdir -p "$DIR"

echo "[*] Adding $NAME..."

if [ -d "$REPO/.git" ]; then
    git -C "$REPO" pull --ff-only || true
else
    git clone "$URL" "$REPO"
fi

find "$REPO" -type f \
    \( -name "*.sh" -o -name "*.py" \) \
    -exec chmod +x {} \; 2>/dev/null || true

if [ -f "$REPO/requirements.txt" ]; then
    python -m pip install -r "$REPO/requirements.txt" || true
fi

cat > "$BIN/$NAME" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

cd "$REPO"

if [ -f main.py ]; then
    python main.py
elif [ -f "$NAME.py" ]; then
    python "$NAME.py"
elif [ -f main.sh ]; then
    bash main.sh
elif [ -f run.sh ]; then
    bash run.sh
else
    echo "Launcher not detected."
    find . -maxdepth 2 -type f | head -50
fi
EOF

chmod +x "$BIN/$NAME"

echo
echo "[✓] $NAME installed."
echo
echo "Run:"
echo "  $NAME"
