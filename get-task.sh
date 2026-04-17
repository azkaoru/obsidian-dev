#!/usr/bin/env bash
# get-task.sh — Obsidian agentTasks/todo/<yyyy-mm>/ からタスクを取得して表示する
# 使用法: bash get-task.sh
#
# 前提:
#   - Obsidian が起動中であること
#   - obsidian-local-rest-api プラグインが有効化されていること
#   - agentTasks/todo/<yyyy-mm>/ にタスクファイルが存在すること
#
# AIエージェント(opencode)への指示プロンプト例:
#   "get-task.sh を実行して Obsidian の agentTasks/todo から最新のタスクを取得し、
#    プロンプトに従って作業してください。
#    作業完了後は complete-task.sh <yyyy-mm/ファイル名> を実行してタスクを完了にしてください。"

set -euo pipefail

# ───────────────────────────────────────────────
# 設定
# ───────────────────────────────────────────────
# API キーは環境変数 OBSIDIAN_API_KEY から読み込む（~/.bashrc に設定してください）
if [ -z "${OBSIDIAN_API_KEY:-}" ]; then
	echo "エラー: 環境変数 OBSIDIAN_API_KEY が設定されていません。"
	echo "   ~/.bashrc に以下を追記してください:"
	echo "   export OBSIDIAN_API_KEY=\"<Local REST API プラグインの API キー>\""
	exit 1
fi
API_KEY="$OBSIDIAN_API_KEY"
BASE_URL="https://127.0.0.1:27124"
TASK_DIR="agentTasks/todo"

# ───────────────────────────────────────────────
# 依存コマンドチェック
# ───────────────────────────────────────────────
for cmd in curl jq python3; do
	if ! command -v "$cmd" &>/dev/null; then
		echo "エラー: '$cmd' が見つかりません。インストールしてから再実行してください。"
		exit 1
	fi
done

# ───────────────────────────────────────────────
# REST API ヘルパー関数
# ───────────────────────────────────────────────
api_get_json() {
	local path="$1"
	curl -sk \
		-H "Authorization: Bearer $API_KEY" \
		-H "Accept: application/json" \
		"${BASE_URL}/vault/${path}"
}

api_get_markdown() {
	local path="$1"
	curl -sk \
		-H "Authorization: Bearer $API_KEY" \
		-H "Accept: text/markdown" \
		"${BASE_URL}/vault/${path}"
}

# ───────────────────────────────────────────────
# Obsidian API 接続確認
# ───────────────────────────────────────────────
echo "▶ Obsidian Local REST API に接続確認中..."
if ! curl -sk -H "Authorization: Bearer $API_KEY" "${BASE_URL}/" &>/dev/null; then
	echo "❌ 接続できません。以下を確認してください:"
	echo "   - Obsidian が起動しているか"
	echo "   - obsidian-local-rest-api プラグインが有効化されているか"
	echo "   - ポート 27124 が使用可能か"
	exit 1
fi
echo "  ✅ 接続成功"
echo ""

# ───────────────────────────────────────────────
# agentTasks/todo/ の yyyy-mm サブフォルダ一覧を取得
# ───────────────────────────────────────────────
echo "▶ タスクフォルダ一覧を取得中 (${TASK_DIR}/)..."

root_response=$(api_get_json "${TASK_DIR}/")

# サブフォルダ（末尾が / で終わるエントリ）を取得し、降順ソート（新しい月が先）
subdir_list=$(echo "$root_response" | jq -r '.files[]? | select(endswith("/"))' 2>/dev/null |
	sort -r || echo "")

if [ -z "$subdir_list" ]; then
	echo "  ℹ️  agentTasks/todo/ に月別フォルダがありません。"
	echo "     Obsidian で Ctrl+P → 「新規タスク」からタスクを作成してください。"
	exit 0
fi

echo "  ✅ 月別フォルダが見つかりました: $(echo "$subdir_list" | tr '\n' ' ')"
echo ""

# ───────────────────────────────────────────────
# 各 yyyy-mm フォルダ内の .md ファイルを収集
# ───────────────────────────────────────────────
declare -A task_priority_map
declare -A task_content_map

while IFS= read -r subdir; do
	# subdir は "2026-04/" のような形式
	month_path="${TASK_DIR}/${subdir}"

	dir_response=$(api_get_json "${month_path}")
	file_list=$(echo "$dir_response" | jq -r '.files[]? | select(endswith(".md"))' 2>/dev/null || echo "")

	if [ -z "$file_list" ]; then
		continue
	fi

	while IFS= read -r filepath; do
		filename=$(basename "$filepath")
		full_rel_path="${subdir%/}/${filename}" # 例: 2026-04/R8-AI-0417-setup修正.md

		# ファイル内容を取得
		content=$(api_get_markdown "${TASK_DIR}/${full_rel_path}")

		if [ -z "$content" ]; then
			continue
		fi

		# frontmatter から各フィールドを抽出
		priority=$(echo "$content" | python3 -c "
import sys, re
text = sys.stdin.read()
m = re.search(r'^priority:\s*(\S+)', text, re.MULTILINE)
print(m.group(1).strip('\"') if m else 'medium')
")

		created=$(echo "$content" | python3 -c "
import sys, re
text = sys.stdin.read()
m = re.search(r'^created:\s*(\S+)', text, re.MULTILINE)
print(m.group(1).strip('\"') if m else '')
")

		# ## プロンプト セクションを抽出
		prompt_section=$(echo "$content" | python3 -c "
import sys, re
text = sys.stdin.read()
m = re.search(r'## プロンプト\s*\n(.*?)(?=\n## |\Z)', text, re.DOTALL)
print(m.group(1).strip() if m else '（プロンプトが記載されていません）')
")

		# ## 内容 セクションを抽出
		description_section=$(echo "$content" | python3 -c "
import sys, re
text = sys.stdin.read()
m = re.search(r'## 内容\s*\n(.*?)(?=\n## |\Z)', text, re.DOTALL)
print(m.group(1).strip() if m else '')
")

		# タスクタイトルを抽出
		task_title=$(echo "$content" | python3 -c "
import sys, re
text = sys.stdin.read()
m = re.search(r'^# (.+)', text, re.MULTILINE)
print(m.group(1).strip() if m else '')
")

		# priority を数値に変換（ソート用）
		case "$priority" in
		high) priority_num=1 ;;
		medium) priority_num=2 ;;
		low) priority_num=3 ;;
		*) priority_num=2 ;;
		esac

		# タスク表示テキストを構築
		task_output="$(
			cat <<TASK_EOF
========================================
タスクファイル: ${TASK_DIR}/${full_rel_path}
タイトル:       ${task_title}
優先度:         ${priority}
作成日:         ${created}
========================================

## 内容
${description_section}

## プロンプト
${prompt_section}

TASK_EOF
		)"

		# キー: priority_num + subdir + filename（ソート用）
		sort_key="${priority_num}_${subdir%/}_${filename}"
		task_priority_map["${sort_key}"]="$priority_num"
		task_content_map["${sort_key}"]="$task_output"

	done <<<"$file_list"

done <<<"$subdir_list"

# ───────────────────────────────────────────────
# 優先度順（high → medium → low）で出力
# ───────────────────────────────────────────────
task_count=${#task_content_map[@]}

if [ "$task_count" -eq 0 ]; then
	echo "  ℹ️  有効なタスクが見つかりませんでした。"
	exit 0
fi

echo "  ✅ ${task_count} 件のタスクが見つかりました"
echo ""
echo "========================================"
echo " AIエージェント向けタスク一覧"
echo "========================================"
echo ""

# キーをソートして出力
for key in $(echo "${!task_content_map[@]}" | tr ' ' '\n' | sort); do
	echo "${task_content_map[$key]}"
done

echo "========================================"
echo " 作業完了後は以下のコマンドでタスクを完了にしてください:"
echo "   bash complete-task.sh <yyyy-mm/ファイル名> [成果物のvault内パス ...]"
echo "   例（成果物なし）: bash complete-task.sh 2026-04/r8-ai-0417-setup修正.md"
echo "   例（成果物あり）: bash complete-task.sh 2026-04/r8-ai-0417-foobartask.md \\"
echo "                       agentTasks/_ai_working/$(date +%Y-%m-%d)/dog-bark.sh"
echo ""
echo " ℹ️  成果物ファイルの保存方法:"
echo "   作業で生成したファイル（スクリプト・コード・レポートなど）は"
echo "   Obsidian REST API の PUT で Vault 内の以下のパスに直接保存してください:"
echo "     agentTasks/_ai_working/$(date +%Y-%m-%d)/<ファイル名>"
echo ""
echo "   PUT コマンド例:"
echo "     curl -sk -X PUT \\"
echo "       -H 'Authorization: Bearer \$API_KEY' \\"
echo "       -H 'Content-Type: text/plain' \\"
echo "       --data-binary '@<ローカルファイル>' \\"
echo "       'https://127.0.0.1:27124/vault/agentTasks/_ai_working/$(date +%Y-%m-%d)/<ファイル名>'"
echo ""
echo "   complete-task.sh が自動で agentTasks/ai_outputs/$(date +%Y-%m-%d)/ にコピーし、"
echo "   _ai_working/ から削除して、タスクファイルに [[Obsidianリンク]] を追記します。"
echo "========================================"
