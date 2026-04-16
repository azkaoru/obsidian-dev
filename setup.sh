#!/usr/bin/env bash
# setup.sh — Obsidian プラグイン自動インストール・有効化スクリプト
# 使用法: bash setup.sh <vault-path>
#
# AIエージェントへのタスク管理用 推奨プラグイン（最大10個）を
# 指定した Obsidian ボルトにインストールし、有効化します。

set -euo pipefail

# ───────────────────────────────────────────────
# 引数チェック
# ───────────────────────────────────────────────
if [ $# -lt 1 ]; then
  echo "使用法: $0 <vault-path>"
  echo "例:     $0 ~/Documents/MyVault"
  exit 1
fi

VAULT_DIR="${1%/}"   # 末尾スラッシュを除去

if [ ! -d "$VAULT_DIR" ]; then
  echo "エラー: ボルトディレクトリが見つかりません: $VAULT_DIR"
  exit 1
fi

PLUGINS_DIR="$VAULT_DIR/.obsidian/plugins"
CONFIG_DIR="$VAULT_DIR/.obsidian"
COMMUNITY_PLUGINS_JSON="$CONFIG_DIR/community-plugins.json"

# ───────────────────────────────────────────────
# ディレクトリ準備
# ───────────────────────────────────────────────
mkdir -p "$PLUGINS_DIR"
mkdir -p "$CONFIG_DIR"

echo "========================================"
echo " Obsidian プラグインセットアップ開始"
echo " ボルト: $VAULT_DIR"
echo "========================================"

# ───────────────────────────────────────────────
# プラグイン定義
# 形式: "plugin-id|GitHub-owner/repo"
# ───────────────────────────────────────────────
PLUGINS=(
  "obsidian-tasks-plugin|obsidian-tasks-group/obsidian-tasks"
  "dataview|blacksmithgu/obsidian-dataview"
  "templater-obsidian|SilentVoid13/Templater"
  "quickadd|chhoumann/quickadd"
  "obsidian-kanban|mgmeyers/obsidian-kanban"
  "periodic-notes|liamcain/obsidian-periodic-notes"
  "calendar|liamcain/obsidian-calendar-plugin"
  "tag-wrangler|pjeby/tag-wrangler"
  "obsidian-git|denolehov/obsidian-git"
  "advanced-tables-obsidian|tgrosinger/advanced-tables-obsidian"
)

# ───────────────────────────────────────────────
# 依存コマンドチェック
# ───────────────────────────────────────────────
for cmd in curl jq; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "エラー: '$cmd' が見つかりません。インストールしてから再実行してください。"
    exit 1
  fi
done

# ───────────────────────────────────────────────
# プラグインインストール関数
# ───────────────────────────────────────────────
install_plugin() {
  local plugin_id="$1"
  local repo="$2"
  local dest="$PLUGINS_DIR/$plugin_id"

  echo ""
  echo "▶ [$plugin_id] インストール中 (${repo})..."

  # GitHub Releases から最新バージョンを取得
  local api_url="https://api.github.com/repos/${repo}/releases/latest"
  local release_info
  release_info=$(curl -fsSL "$api_url" 2>/dev/null) || {
    echo "  ⚠️  リリース情報の取得に失敗しました。スキップします: $plugin_id"
    return 0
  }

  local tag
  tag=$(echo "$release_info" | jq -r '.tag_name // empty')

  if [ -z "$tag" ]; then
    echo "  ⚠️  最新タグが見つかりません。スキップします: $plugin_id"
    return 0
  fi

  mkdir -p "$dest"

  # 必要ファイルをダウンロード
  local base_url="https://github.com/${repo}/releases/download/${tag}"
  local files=("main.js" "manifest.json" "styles.css")

  for file in "${files[@]}"; do
    local url="${base_url}/${file}"
    if curl -fsSL -o "$dest/$file" "$url" 2>/dev/null; then
      echo "  ✅ $file ダウンロード完了"
    else
      # styles.css は存在しないプラグインもあるため警告のみ
      if [ "$file" != "styles.css" ]; then
        echo "  ⚠️  $file のダウンロードに失敗しました"
      fi
      rm -f "$dest/$file"
    fi
  done

  echo "  ✅ $plugin_id インストール完了 (${tag})"
}

# ───────────────────────────────────────────────
# 全プラグインをインストール
# ───────────────────────────────────────────────
INSTALLED_IDS=()

for entry in "${PLUGINS[@]}"; do
  IFS="|" read -r plugin_id repo <<< "$entry"
  install_plugin "$plugin_id" "$repo"

  # manifest.json が存在する場合のみ有効化リストに追加
  if [ -f "$PLUGINS_DIR/$plugin_id/manifest.json" ]; then
    INSTALLED_IDS+=("$plugin_id")
  fi
done

# ───────────────────────────────────────────────
# community-plugins.json を更新して有効化
# ───────────────────────────────────────────────
echo ""
echo "▶ プラグインを有効化しています..."

# 既存の有効プラグインリストを読み込む（存在しない場合は空配列）
existing_plugins="[]"
if [ -f "$COMMUNITY_PLUGINS_JSON" ]; then
  existing_plugins=$(cat "$COMMUNITY_PLUGINS_JSON")
  # JSON が配列でない場合はリセット
  if ! echo "$existing_plugins" | jq -e 'if type == "array" then true else false end' &>/dev/null; then
    existing_plugins="[]"
  fi
fi

# 新規プラグインを既存リストにマージ（重複除去）
new_list="$existing_plugins"
for id in "${INSTALLED_IDS[@]}"; do
  already=$(echo "$new_list" | jq -r --arg id "$id" 'map(select(. == $id)) | length')
  if [ "$already" -eq 0 ]; then
    new_list=$(echo "$new_list" | jq -r --arg id "$id" '. + [$id]')
  fi
done

echo "$new_list" | jq '.' > "$COMMUNITY_PLUGINS_JSON"
echo "  ✅ $COMMUNITY_PLUGINS_JSON を更新しました"

# ───────────────────────────────────────────────
# サマリー
# ───────────────────────────────────────────────
echo ""
echo "========================================"
echo " セットアップ完了!"
echo "========================================"
echo " 有効化されたプラグイン:"
for id in "${INSTALLED_IDS[@]}"; do
  echo "   - $id"
done
echo ""
echo "⚠️  Obsidian アプリを再起動してプラグインを反映してください。"
echo "    設定 > コミュニティプラグイン > 各プラグインをオンにしてください。"
