#!/usr/bin/env bash
# setup.sh — Obsidian プラグイン自動インストール・有効化スクリプト
# 使用法: bash setup.sh <vault-path>
#
# AIエージェントへのタスク管理用 推奨プラグインを
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

VAULT_DIR="${1%/}" # 末尾スラッシュを除去

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

# ───────────────────────────────────────────────
# ボルト内ディレクトリ構成の作成
# ───────────────────────────────────────────────
VAULT_DIRS=(
	"activityJournals"
	"thoughtSpace"
	"knowledge"
	"_templates"
	"_assets/images"
	"agentTasks/todo"
	"agentTasks/in_progress"
	"agentTasks/done"
	"agentTasks/ai_outputs"
	"agentTasks/_ai_working"
)

# 当月の yyyy-mm サブフォルダを自動作成（todo / in_progress / done）
CURRENT_MONTH=$(date +%Y-%m)
# 本日の yyyy-mm-dd サブフォルダを自動作成（ai_outputs / _ai_working）
CURRENT_DATE=$(date +%Y-%m-%d)
VAULT_DIRS+=(
	"agentTasks/todo/${CURRENT_MONTH}"
	"agentTasks/in_progress/${CURRENT_MONTH}"
	"agentTasks/done/${CURRENT_MONTH}"
	"agentTasks/ai_outputs/${CURRENT_DATE}"
	"agentTasks/_ai_working/${CURRENT_DATE}"
)

echo "▶ ボルト内ディレクトリを作成しています..."
for dir in "${VAULT_DIRS[@]}"; do
	mkdir -p "$VAULT_DIR/$dir"
	echo "  ✅ $dir"
done

# ───────────────────────────────────────────────
# デイリーノートテンプレートの作成
# ───────────────────────────────────────────────
TEMPLATE_FILE="$VAULT_DIR/_templates/DailyNotesTemplate.md"
if [ ! -f "$TEMPLATE_FILE" ]; then
	cat >"$TEMPLATE_FILE" <<'EOF'
---
tags:
  - "#journal"
  - "#journal/daily"
date: "{{date:YYYY-MM-DD}}"
---
# 🗒️ {{date:YYYY-MM-DD(ddd)}} Journal

## ⏱️ Timeline
- 08:00 xx

## ✅ 今日のTODO
- [ ] 


## 雑記

### ✨ 気づき／学び
- 
### 🚧 課題／懸念
- 
### 💭 振り返り・感想 (YWT:やった・わかった・つぎにやる)
- **Y** (Timelineに書くので省略)
- **W**  
- **T**
EOF
	echo "  ✅ _templates/DailyNotesTemplate.md を作成しました"
else
	echo "  ℹ️  _templates/DailyNotesTemplate.md は既に存在します。スキップします"
fi

# ───────────────────────────────────────────────
# タスクテンプレートの作成
# ───────────────────────────────────────────────
TASK_TEMPLATE_FILE="$VAULT_DIR/_templates/TaskTemplate.md"
# テンプレートは常に最新化する（Templaterロジック変更に対応）
cat >"$TASK_TEMPLATE_FILE" <<'EOF'
<%*
// ── ファイル名を R<令和年>-<カテゴリ>-<MMDD>-<タイトル> 形式にリネーム ──
const originalTitle = tp.file.title;
const reiwa = Number(tp.date.now("YYYY")) - 2018;
const mmdd = tp.date.now("MMDD");
const category = await tp.system.prompt("カテゴリを入力 (例: AI, DEV, OPS)");
const newName = `r${reiwa}-${category.toLowerCase()}-${mmdd}-${originalTitle}`;
await tp.file.rename(newName);
-%>
---
status: todo
priority: <% await tp.system.suggester(["high", "medium", "low"], ["high", "medium", "low"]) %>
created: <% tp.date.now("YYYY-MM-DD") %>
---

# <% tp.file.title %>

## 内容


## プロンプト

EOF
echo "  ✅ _templates/TaskTemplate.md を作成／更新しました"

# ───────────────────────────────────────────────
# Obsidian 設定ファイルの生成
# ───────────────────────────────────────────────
echo ""
echo "▶ Obsidian 設定ファイルを生成しています..."

# app.json — Files & Links 設定
APP_JSON="$CONFIG_DIR/app.json"
existing_app="{}"
if [ -f "$APP_JSON" ]; then
	if jq -e . "$APP_JSON" &>/dev/null; then
		existing_app=$(cat "$APP_JSON")
	else
		echo "  ⚠️  app.json の JSON が不正です。初期化して続行します"
	fi
fi
echo "$existing_app" | jq '. + {
  "newFileLocation": "current",
  "attachmentFolderPath": "_assets/images",
  "showBacklinksAtBottom": true,
  "showUnsupportedFiles": true
}' >"$APP_JSON"
echo "  ✅ app.json (Files & Links / Backlinks 設定)"

# daily-notes.json — Daily Notes 設定
DAILY_NOTES_JSON="$CONFIG_DIR/daily-notes.json"
existing_dn="{}"
if [ -f "$DAILY_NOTES_JSON" ]; then
	if jq -e . "$DAILY_NOTES_JSON" &>/dev/null; then
		existing_dn=$(cat "$DAILY_NOTES_JSON")
	else
		echo "  ⚠️  daily-notes.json の JSON が不正です。初期化して続行します"
	fi
fi
echo "$existing_dn" | jq '. + {
  "folder": "activityJournals",
  "format": "YYYY/MM/DD/YYYY-MM-DD",
  "template": "_templates/DailyNotesTemplate.md"
}' >"$DAILY_NOTES_JSON"
echo "  ✅ daily-notes.json (Daily Notes 設定)"

# templates.json — Templates 設定
TEMPLATES_JSON="$CONFIG_DIR/templates.json"
existing_tmpl="{}"
if [ -f "$TEMPLATES_JSON" ]; then
	if jq -e . "$TEMPLATES_JSON" &>/dev/null; then
		existing_tmpl=$(cat "$TEMPLATES_JSON")
	else
		echo "  ⚠️  templates.json の JSON が不正です。初期化して続行します"
	fi
fi
echo "$existing_tmpl" | jq '. + {
  "folder": "_templates"
}' >"$TEMPLATES_JSON"
echo "  ✅ templates.json (Templates 設定)"


# quickadd の data.json — 新規タスク作成マクロを登録
QUICKADD_DATA_JSON="$PLUGINS_DIR/quickadd/data.json"
if [ -f "$QUICKADD_DATA_JSON" ]; then
	if jq -e . "$QUICKADD_DATA_JSON" &>/dev/null; then
		# 「新規タスク」チョイスが未登録なら追加、登録済みなら folder/fileNameFormat を最新化
		already_exists=$(jq -r '[.choices[] | select(.name == "新規タスク")] | length' "$QUICKADD_DATA_JSON" 2>/dev/null || echo "0")
		NEW_TASK_ENTRY='{
          "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
          "name": "新規タスク",
          "type": "Template",
          "command": true,
          "useTemplater": true,
          "templatePath": "_templates/TaskTemplate.md",
          "fileNameFormat": {
            "enabled": true,
            "format": "{{NAME}}"
          },
          "folder": {
            "enabled": true,
            "folders": ["agentTasks/todo/{{DATE:YYYY-MM}}"],
            "chooseWhenCreatingNote": false
          },
          "openFile": true,
          "openFileInMode": "default",
          "setFileExistsBehavior": false,
          "fileExistsMode": "Increment the file name"
        }'
		if [ "$already_exists" -eq 0 ]; then
			jq --argjson entry "$NEW_TASK_ENTRY" '.choices += [$entry]' \
				"$QUICKADD_DATA_JSON" >"$QUICKADD_DATA_JSON.tmp" && mv "$QUICKADD_DATA_JSON.tmp" "$QUICKADD_DATA_JSON"
			echo "  ✅ quickadd/data.json に「新規タスク」マクロを登録しました"
		else
			# 既存エントリの folder と fileNameFormat を更新
			jq --argjson entry "$NEW_TASK_ENTRY" \
				'(.choices[] | select(.name == "新規タスク")) |= $entry' \
				"$QUICKADD_DATA_JSON" >"$QUICKADD_DATA_JSON.tmp" && mv "$QUICKADD_DATA_JSON.tmp" "$QUICKADD_DATA_JSON"
			echo "  ✅ quickadd/data.json の「新規タスク」マクロを最新化しました"
		fi
	else
		echo "  ⚠️  quickadd/data.json の JSON が不正です。スキップします"
	fi
else
	echo "  ⚠️  quickadd/data.json が見つかりません。QuickAdd プラグインのインストール後に再実行してください"
fi

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
	"periodic-notes|liamcain/obsidian-periodic-notes"
	"calendar|liamcain/obsidian-calendar-plugin|1.5.10"
	"obsidian-local-rest-api|coddingtonbear/obsidian-local-rest-api"
	"vscode-editor|sunxvming/obsidian-vscode-editor"
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
	local pinned_version="${3:-}"
	local dest="$PLUGINS_DIR/$plugin_id"

	echo ""
	echo "▶ [$plugin_id] インストール中 (${repo})..."

	local tag
	if [ -n "$pinned_version" ]; then
		# バージョンが固定指定されている場合はそのタグを使用
		tag="$pinned_version"
		echo "  ℹ️  バージョン固定: $tag"
	else
		# GitHub Releases から最新バージョンを取得
		local api_url="https://api.github.com/repos/${repo}/releases/latest"
		local release_info
		release_info=$(curl -fsSL "$api_url" 2>/dev/null) || {
			echo "  ⚠️  リリース情報の取得に失敗しました。スキップします: $plugin_id"
			return 0
		}

		tag=$(echo "$release_info" | jq -r '.tag_name // empty')

		if [ -z "$tag" ]; then
			echo "  ⚠️  最新タグが見つかりません。スキップします: $plugin_id"
			return 0
		fi
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
	IFS="|" read -r plugin_id repo pinned_version <<<"$entry"
	install_plugin "$plugin_id" "$repo" "$pinned_version"

	# manifest.json が存在する場合のみ有効化リストに追加
	if [ -d "$PLUGINS_DIR/$plugin_id" ]; then
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

# vscode-editor の data.json — 対応拡張子に sh を追加
VSCODE_EDITOR_DATA_JSON="$PLUGINS_DIR/vscode-editor/data.json"
existing_vscode='{}'
if [ -f "$VSCODE_EDITOR_DATA_JSON" ]; then
	if jq -e . "$VSCODE_EDITOR_DATA_JSON" &>/dev/null; then
		existing_vscode=$(cat "$VSCODE_EDITOR_DATA_JSON")
	else
		echo "  ⚠️  vscode-editor/data.json の JSON が不正です。初期化して続行します"
	fi
fi
# extensions が未設定の場合はデフォルト＋sh を設定、設定済みの場合は sh を追加
echo "$existing_vscode" | python3 -c "
import sys, json
data = json.load(sys.stdin)
default_ext = ['ts','js','py','css','c','cpp','go','rs','java','lua','php','cs','sh']
exts = data.get('extensions', default_ext)
if 'sh' not in exts:
    exts.append('sh')
data['extensions'] = exts
# デフォルト設定がない場合は補完
data.setdefault('folding', True)
data.setdefault('lineNumbers', True)
data.setdefault('wordWrap', True)
data.setdefault('minimap', True)
data.setdefault('themeColor', 'AUTO')
data.setdefault('fontSize', 14)
print(json.dumps(data, indent=2, ensure_ascii=False))
" >"$VSCODE_EDITOR_DATA_JSON"
echo "  ✅ vscode-editor/data.json (対応拡張子: sh 追加)"

echo "$new_list" | jq '.' >"$COMMUNITY_PLUGINS_JSON"
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
echo "ℹ️  Obsidian アプリを再起動してプラグインを反映してください。"
echo "   プラグインは community-plugins.json に登録済みのため、"
echo "   再起動後に自動で有効化されます。"
