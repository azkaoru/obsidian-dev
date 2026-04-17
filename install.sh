#!/bin/bash

set -e

# ===== 設定 =====
APP_NAME="Obsidian"
VERSION="1.12.7"
APPIMAGE_NAME="Obsidian-${VERSION}.AppImage"
DOWNLOAD_URL="https://github.com/obsidianmd/obsidian-releases/releases/download/v${VERSION}/${APPIMAGE_NAME}"

INSTALL_DIR="$HOME/Applications"
DESKTOP_FILE="$HOME/.local/share/applications/obsidian.desktop"
DESKTOP_SHORTCUT="$HOME/Desktop/obsidian.desktop"
ICON_DIR="$HOME/.local/share/icons"
ICON_PATH="$ICON_DIR/obsidian.png"

# ===== ディレクトリ作成 =====
mkdir -p "$INSTALL_DIR"
mkdir -p "$(dirname "$DESKTOP_FILE")"
mkdir -p "$ICON_DIR"

# ===== ダウンロード =====
echo "Downloading ${APPIMAGE_NAME}..."
curl -L "$DOWNLOAD_URL" -o "$INSTALL_DIR/$APPIMAGE_NAME"

# ===== 実行権限付与 =====
chmod +x "$INSTALL_DIR/$APPIMAGE_NAME"

# ===== アイコンダウンロード（任意）=====
echo "Downloading icon..."
curl -L https://raw.githubusercontent.com/obsidianmd/obsidian-releases/master/obsidian.png -o "$ICON_PATH" || true

# ===== .desktop ファイル作成 =====
echo "Creating desktop entry..."
cat > "$DESKTOP_FILE" <<EOF
[Desktop Entry]
Name=${APP_NAME}
Exec=${INSTALL_DIR}/${APPIMAGE_NAME}
Icon=${ICON_PATH}
Type=Application
Categories=Utility;
Terminal=false
EOF

# ===== デスクトップにコピー =====
cp "$DESKTOP_FILE" "$DESKTOP_SHORTCUT"
chmod +x "$DESKTOP_SHORTCUT"

echo "=================================="
echo "インストール完了"
echo "デスクトップに Obsidian アイコンを作成しました"
echo "※ 初回は右クリック → 『実行を許可』が必要です"
echo "=================================="

