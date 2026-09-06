#!/data/data/com.termux/files/usr/bin/bash

set -e

REPO_DIR="$HOME/.krishn-repo"
BIN_DIR="$PREFIX/bin"

DIGAI_URL="https://github.com/Krishn-145/DIGAI.git"
VENOM_URL="https://github.com/Krishn-145/VENOM.git"

GPG_KEY_FILE="$REPO_DIR/keys/krishn-repo.asc"
EXPECTED_FINGERPRINT="AA722496E5BBCF04A50E8E3958EC97FB6D49240B"

clear

echo "╔══════════════════════════════════════╗"
echo "║          K R I S H N  R E P O        ║"
echo "║            TERMUX INSTALLER          ║"
echo "╚══════════════════════════════════════╝"
echo

# Check Termux
if [ -z "$PREFIX" ]; then
    echo "[✗] Please run this inside Termux."
    exit 1
fi

echo "[✓] Termux detected"

# Update packages
echo "[*] Updating packages..."
pkg update -y

# Install required packages
echo "[*] Installing required packages..."
pkg install -y git bash python gnupg curl

mkdir -p "$REPO_DIR"
mkdir -p "$REPO_DIR/keys"

# Download GPG public key
echo
echo "[*] Downloading Krishn GPG public key..."

GPG_URL="https://raw.githubusercontent.com/kalidrod/krishn/main/keys/krishn-repo.asc"

if curl -fsSL "$GPG_URL" -o "$GPG_KEY_FILE"; then
    echo "[✓] GPG public key downloaded"
else
    echo "[✗] Could not download GPG public key"
    exit 1
fi

# Verify GPG fingerprint
echo
echo "[*] Verifying GPG fingerprint..."

ACTUAL_FINGERPRINT="$(
    gpg --with-colons --import-options show-only \
    --import "$GPG_KEY_FILE" 2>/dev/null |
    awk -F: '$1=="fpr" {print $10; exit}'
)"

ACTUAL_FINGERPRINT="$(echo "$ACTUAL_FINGERPRINT" | tr '[:lower:]' '[:upper:]')"
EXPECTED_FINGERPRINT="$(echo "$EXPECTED_FINGERPRINT" | tr '[:lower:]' '[:upper:]')"

if [ "$ACTUAL_FINGERPRINT" != "$EXPECTED_FINGERPRINT" ]; then
    echo "[✗] GPG fingerprint verification failed."
    echo
    echo "Expected:"
    echo "$EXPECTED_FINGERPRINT"
    echo
    echo "Found:"
    echo "$ACTUAL_FINGERPRINT"
    exit 1
fi

echo "[✓] GPG key verified"
echo "[✓] Fingerprint: $ACTUAL_FINGERPRINT"

# Import verified key
gpg --import "$GPG_KEY_FILE" >/dev/null 2>&1 || true

# Install DIGAI
echo
echo "──────────────────────────────────────"
echo " Installing DIGAI"
echo "──────────────────────────────────────"

if [ -d "$REPO_DIR/DIGAI/.git" ]; then
    cd "$REPO_DIR/DIGAI"
    git pull --ff-only || true
else
    git clone "$DIGAI_URL" "$REPO_DIR/DIGAI"
fi

echo "[✓] DIGAI installed"

# Install VENOM
echo
echo "──────────────────────────────────────"
echo " Installing VENOM"
echo "──────────────────────────────────────"

if [ -d "$REPO_DIR/VENOM/.git" ]; then
    cd "$REPO_DIR/VENOM"
    git pull --ff-only || true
else
    git clone "$VENOM_URL" "$REPO_DIR/VENOM"
fi

echo "[✓] VENOM installed"

# Permissions
echo
echo "[*] Preparing tools..."

find "$REPO_DIR/DIGAI" -type f \
    \( -name "*.sh" -o -name "*.py" \) \
    -exec chmod +x {} \; 2>/dev/null || true

find "$REPO_DIR/VENOM" -type f \
    \( -name "*.sh" -o -name "*.py" \) \
    -exec chmod +x {} \; 2>/dev/null || true

echo "[✓] Permissions prepared"

# DIGAI command
cat > "$BIN_DIR/digai" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

cd "$REPO_DIR/DIGAI"

echo "Launching DIGAI..."
echo

if [ -f "./main.py" ]; then
    python ./main.py
elif [ -f "./digai.py" ]; then
    python ./digai.py
elif [ -f "./main.sh" ]; then
    bash ./main.sh
elif [ -f "./run.sh" ]; then
    bash ./run.sh
else
    echo "[!] DIGAI launcher not detected."
    find . -maxdepth 2 -type f | head -50
fi
EOF

chmod +x "$BIN_DIR/digai"

# VENOM command
cat > "$BIN_DIR/venom" <<EOF
#!/data/data/com.termux/files/usr/bin/bash

cd "$REPO_DIR/VENOM"

echo "Launching VENOM..."
echo

if [ -f "./main.py" ]; then
    python ./main.py
elif [ -f "./venom.py" ]; then
    python ./venom.py
elif [ -f "./main.sh" ]; then
    bash ./main.sh
elif [ -f "./run.sh" ]; then
    bash ./run.sh
else
    echo "[!] VENOM launcher not detected."
    find . -maxdepth 2 -type f | head -50
fi
EOF

chmod +x "$BIN_DIR/venom"

echo
echo "╔══════════════════════════════════════╗"
echo "║       INSTALLATION COMPLETE          ║"
echo "╚══════════════════════════════════════╝"

echo
echo "[✓] GPG key verified"
echo "[✓] DIGAI installed"
echo "[✓] VENOM installed"

echo
echo "Commands:"
echo "  digai"
echo "  venom"
echo
echo "Installation directory:"
echo "  $REPO_DIR"
echo
echo "Krishn Repo installation finished."
