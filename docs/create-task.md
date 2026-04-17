# obsidian create でタスクファイルを作成する

このドキュメントでは、`obsidian` CLI の `create` コマンドを使って  
AIエージェント向けタスクファイルを Vault に直接作成する方法を説明します。

---

## 前提

- `obsidian` CLI がインストール済みで `PATH` が通っていること（`~/.local/bin/obsidian` 等）
- Obsidian が起動中であること
- `obsidian-local-rest-api` プラグインが有効化されていること

---

## コマンド構文

```bash
obsidian create \
  path="<フォルダパス>" \
  name="<ファイル名>.md" \
  content="<ファイル内容>"
```

| オプション | 説明 |
|---|---|
| `path=` | 保存先フォルダ（Vault ルートからの相対パス） |
| `name=` | ファイル名（拡張子 `.md` を含む） |
| `content=` | ファイルの内容。`\n` で改行、`\t` でタブを表現する |
| `template=` | テンプレートを使用する場合はテンプレート名を指定 |
| `overwrite` | 同名ファイルが存在する場合に上書きする |

---

## ファイル名の命名規則

```
r<令和年>-<カテゴリ>-<MMDD>-<タスク名>.md
```

| 部分 | 例 | 説明 |
|---|---|---|
| `r<令和年>` | `r8` | 令和8年 = 2026年 |
| `<カテゴリ>` | `ai` | 作業カテゴリを小文字で記述 |
| `<MMDD>` | `0417` | 作成日（月日4桁） |
| `<タスク名>` | `猫の鳴き声を出力するプログラムを作成` | タスクの内容を簡潔に |

---

## 実行例

### コマンド

```bash
obsidian create \
  path="agentTasks/todo/2026-04" \
  name="r8-ai-0417-猫の鳴き声を出力するプログラムを作成.md" \
  content="---\nstatus: todo\npriority: high\ncreated: 2026-04-17\n---\n\n# 猫の鳴き声を出力するプログラムを作成\n\n## 内容\n\n猫の鳴き声を出力するプログラムを作成する。\n\n## プロンプト\n\npythonスクリプトで指定された間隔（デフォルト1.0秒）で、指定された回数、\n猫の鳴き声（ニャー）を出力するプログラムを作成する。"
```

### 出力

```
Created: agentTasks/todo/2026-04/r8-ai-0417-猫の鳴き声を出力するプログラムを作成.md
```

### 作成されたファイルの内容

```markdown
---
status: todo
priority: high
created: 2026-04-17
---

# 猫の鳴き声を出力するプログラムを作成

## 内容

猫の鳴き声を出力するプログラムを作成する。

## プロンプト

pythonスクリプトで指定された間隔（デフォルト1.0秒）で、指定された回数、
猫の鳴き声（ニャー）を出力するプログラムを作成する。
```

---

## フロントマターの各フィールド

```yaml
---
status: todo        # タスクの状態。todo / in_progress / done
priority: high      # 優先度。high / medium / low
created: 2026-04-17 # 作成日（YYYY-MM-DD）
---
```

`get-task.sh` は `priority` フィールドの値に従い `high → medium → low` の順で表示します。

---

## よく使うスニペット

### 優先度ごとのテンプレート

**high（緊急タスク）**
```bash
obsidian create \
  path="agentTasks/todo/$(date +%Y-%m)" \
  name="r8-ai-$(date +%m%d)-タスク名.md" \
  content="---\nstatus: todo\npriority: high\ncreated: $(date +%Y-%m-%d)\n---\n\n# タスク名\n\n## 内容\n\nここに概要を書く。\n\n## プロンプト\n\nここに詳細な指示を書く。"
```

**medium（通常タスク）**
```bash
obsidian create \
  path="agentTasks/todo/$(date +%Y-%m)" \
  name="r8-ai-$(date +%m%d)-タスク名.md" \
  content="---\nstatus: todo\npriority: medium\ncreated: $(date +%Y-%m-%d)\n---\n\n# タスク名\n\n## 内容\n\nここに概要を書く。\n\n## プロンプト\n\nここに詳細な指示を書く。"
```

---

## タスク作成後のフロー

タスクファイルを作成したら、以下の順番で作業を進めます。

```
obsidian create  →  bash get-task.sh  →  作業・成果物作成  →  bash complete-task.sh
```

詳細な手順は [examples.md](examples.md) を参照してください。

---

## 注意事項

- `content=` の値に `"` （ダブルクォート）を含める場合は `\"` とエスケープしてください
- フォルダ（`path=`）が存在しない場合は自動的に作成されます
- 同名のファイルがすでに存在する場合はエラーになります。上書きしたい場合は `overwrite` オプションを追加してください
