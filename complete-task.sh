#!/usr/bin/env bash
# complete-task.sh — agentTasks/todo/<yyyy-mm>/ のタスクを完了（done）に移動する
#                    成果物を agentTasks/_ai_working/ から agentTasks/ai_outputs/ にコピーし
#                    _ai_working/ からは削除する。タスクファイルに Obsidian リンクを追記する。
#
# 使用法:
#   bash complete-task.sh <yyyy-mm/ファイル名> [成果物1のvault内パス] [成果物2のvault内パス] ...
#
# 例（成果物なし）:
#   bash complete-task.sh 2026-04/r8-ai-0417-foobartask.md
#
# 例（成果物あり）:
#   bash complete-task.sh 2026-04/r8-ai-0417-foobartask.md \
#     agentTasks/_ai_working/2026-04-17/dog-bark.sh \
#     agentTasks/_ai_working/2026-04-17/result.py
#
# 成果物の vault 内パスについて:
#   AIエージェントが作業中に REST API PUT で
#   agentTasks/_ai_working/yyyy-mm-dd/ に保存したファイルのパスを渡してください。
#   このスクリプトが自動で agentTasks/ai_outputs/yyyy-mm-dd/ にコピーし、
#   _ai_working/ から削除します。

set -euo pipefail

# ───────────────────────────────────────────────
# 引数チェック
# ───────────────────────────────────────────────
if [ $# -lt 1 ]; then
	echo "使用法: $0 <yyyy-mm/ファイル名> [成果物のvault内パス ...]"
	echo "例:     $0 2026-04/r8-ai-0417-foobartask.md agentTasks/_ai_working/2026-04-17/dog-bark.sh"
	exit 1
fi

TASK_REL_PATH="$1"
shift
OUTPUT_VAULT_PATHS=("$@") # 残りの引数がすべて成果物の vault 内パス

# yyyy-mm 部分とファイル名を分離
MONTH_DIR=$(dirname "$TASK_REL_PATH") # 例: 2026-04
FILENAME=$(basename "$TASK_REL_PATH") # 例: r8-ai-0417-foobartask.md

# yyyy-mm 形式の検証
if ! echo "$MONTH_DIR" | grep -qE '^[0-9]{4}-[0-9]{2}$'; then
	echo "エラー: 引数は <yyyy-mm/ファイル名> の形式で指定してください。"
	echo "例: $0 2026-04/r8-ai-0417-foobartask.md"
	exit 1
fi

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
SRC_PATH="agentTasks/todo/${MONTH_DIR}/${FILENAME}"
DST_PATH="agentTasks/done/${MONTH_DIR}/${FILENAME}"
CURRENT_DATE=$(date +%Y-%m-%d)
OUTPUTS_DIR="agentTasks/ai_outputs/${CURRENT_DATE}"

echo "▶ タスク: ${TASK_REL_PATH}"
echo "  移動元: ${SRC_PATH}"
echo "  移動先: ${DST_PATH}"
if [ ${#OUTPUT_VAULT_PATHS[@]} -gt 0 ]; then
	echo "  成果物: ${OUTPUT_VAULT_PATHS[*]}"
fi
echo ""

# ───────────────────────────────────────────────
# REST API ヘルパー関数
# ───────────────────────────────────────────────
api_get_markdown() {
	local path="$1"
	curl -sk \
		-H "Authorization: Bearer $API_KEY" \
		-H "Accept: text/markdown" \
		"${BASE_URL}/vault/${path}"
}

api_put() {
	local path="$1"
	local body="$2"
	local content_type="${3:-text/plain}"
	curl -sk -o /dev/null -w "%{http_code}" \
		-X PUT \
		-H "Authorization: Bearer $API_KEY" \
		-H "Content-Type: ${content_type}" \
		--data-raw "$body" \
		"${BASE_URL}/vault/${path}"
}

api_delete() {
	local path="$1"
	curl -sk -o /dev/null -w "%{http_code}" \
		-X DELETE \
		-H "Authorization: Bearer $API_KEY" \
		"${BASE_URL}/vault/${path}"
}

# ───────────────────────────────────────────────
# 1. ソースファイルの内容を取得
# ───────────────────────────────────────────────
echo "▶ タスクを取得中..."
content=$(api_get_markdown "${SRC_PATH}")

if [ -z "$content" ]; then
	echo "❌ ファイルが見つかりません: ${SRC_PATH}"
	echo "   get-task.sh の出力に表示されたファイルパスを確認してください。"
	exit 1
fi
echo "  ✅ タスク取得完了"

# ───────────────────────────────────────────────
# 2. 成果物を _ai_working/ から ai_outputs/ にコピーして _ai_working/ から削除
# ───────────────────────────────────────────────
UPLOADED_NAMES=()

if [ ${#OUTPUT_VAULT_PATHS[@]} -gt 0 ]; then
	echo ""
	echo "▶ 成果物を ai_outputs/ にコピー中 (${OUTPUTS_DIR}/)..."

	for vault_src_path in "${OUTPUT_VAULT_PATHS[@]}"; do
		output_filename=$(basename "$vault_src_path")
		vault_dst_path="${OUTPUTS_DIR}/${output_filename}"

		# vault 内のソースファイルを取得
		file_content=$(curl -sk \
			-H "Authorization: Bearer $API_KEY" \
			-H "Accept: text/plain" \
			"${BASE_URL}/vault/${vault_src_path}")

		if [ -z "$file_content" ]; then
			echo "  ⚠️  vault 内にファイルが見つかりません。スキップします: ${vault_src_path}"
			continue
		fi

		# ai_outputs/ に PUT（コピー）
		http_code=$(api_put "$vault_dst_path" "$file_content" "text/plain")

		if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
			echo "  ✅ コピー完了: ${output_filename} → ${vault_dst_path} (HTTP ${http_code})"
			UPLOADED_NAMES+=("$output_filename")

			# _ai_working/ から DELETE（削除）
			del_code=$(api_delete "$vault_src_path")
			if [ "$del_code" -ge 200 ] && [ "$del_code" -lt 300 ]; then
				echo "  🗑️  削除完了: ${vault_src_path} (HTTP ${del_code})"
			else
				echo "  ⚠️  _ai_working/ からの削除に失敗しました (HTTP ${del_code}): ${vault_src_path}"
			fi
		else
			echo "  ❌ コピー失敗: ${output_filename} (HTTP ${http_code})"
		fi
	done
fi

# ───────────────────────────────────────────────
# 3. status を done に更新 & ## 成果物 セクションを追記
# ───────────────────────────────────────────────
updated_content=$(echo "$content" | python3 -c "
import sys, re
text = sys.stdin.read()
text = re.sub(r'^(status:\s*)todo', r'\1done', text, flags=re.MULTILINE)
text = re.sub(r'^(status:\s*)in_progress', r'\1done', text, flags=re.MULTILINE)
sys.stdout.write(text)
")

# ## 成果物 セクションを追記（アップロードできたファイルがある場合）
if [ ${#UPLOADED_NAMES[@]} -gt 0 ]; then
	links_text=""
	for name in "${UPLOADED_NAMES[@]}"; do
		links_text+="- [[${name}]]"$'\n'
	done

	updated_content=$(echo "$updated_content" | python3 -c "
import sys, re
text = sys.stdin.read()
links = '''${links_text}'''.strip()

if re.search(r'^## 成果物', text, re.MULTILINE):
    # 既存の ## 成果物 セクションの末尾に追記
    text = re.sub(
        r'(## 成果物\s*\n)(.*?)(\Z)',
        lambda m: m.group(1) + m.group(2).rstrip() + '\n' + links + '\n',
        text, flags=re.DOTALL
    )
else:
    # ファイル末尾に ## 成果物 セクションを追加
    text = text.rstrip() + '\n\n## 成果物\n' + links + '\n'

sys.stdout.write(text)
")
	echo ""
	echo "▶ タスクファイルに成果物リンクを追記しました:"
	for name in "${UPLOADED_NAMES[@]}"; do
		echo "  - [[${name}]]"
	done
fi

# ───────────────────────────────────────────────
# 4. done/<yyyy-mm>/ フォルダに書き込み
# ───────────────────────────────────────────────
echo ""
echo "▶ done フォルダに移動中: ${DST_PATH}"
http_code=$(curl -sk -o /dev/null -w "%{http_code}" \
	-X PUT \
	-H "Authorization: Bearer $API_KEY" \
	-H "Content-Type: text/markdown" \
	--data-raw "$updated_content" \
	"${BASE_URL}/vault/${DST_PATH}")

if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
	echo "  ✅ done フォルダへの書き込み完了 (HTTP ${http_code})"
else
	echo "  ❌ 書き込み失敗 (HTTP ${http_code})"
	exit 1
fi

# ───────────────────────────────────────────────
# 5. todo/<yyyy-mm>/ から削除
# ───────────────────────────────────────────────
echo "▶ todo フォルダから削除中: ${SRC_PATH}"
http_code=$(api_delete "${SRC_PATH}")

if [ "$http_code" -ge 200 ] && [ "$http_code" -lt 300 ]; then
	echo "  ✅ todo フォルダから削除完了 (HTTP ${http_code})"
else
	echo "  ❌ 削除失敗 (HTTP ${http_code})"
	exit 1
fi

echo ""
echo "✅ タスク完了: ${TASK_REL_PATH}"
echo "   agentTasks/todo/${MONTH_DIR}/ → agentTasks/done/${MONTH_DIR}/ に移動しました。"
if [ ${#UPLOADED_NAMES[@]} -gt 0 ]; then
	echo "   成果物 → agentTasks/ai_outputs/${CURRENT_DATE}/ に保存しました。"
	echo "   Obsidian でタスクファイルを開くと [[リンク]] から成果物を参照できます。"
fi
