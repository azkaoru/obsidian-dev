# 実行例：タスク作成から完了までの一連フロー

このドキュメントでは、実際に Obsidian 上で作成したタスクを例に、  
`get-task.sh` → 作業 → `complete-task.sh` の一連フローを具体的な出力とともに説明します。

---

## 題材タスク

Obsidian のコマンドパレット（`Ctrl+P` → 「新規タスク」）で作成したタスクファイルです。

**ファイルパス：**
```
agentTasks/todo/2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md
```

**ファイル内容：**
```markdown
---
status: todo
priority: medium
created: 2026-04-17
---

# 犬の鳴き声を出力するプログラムを作成

## 内容

犬の鳴き声を出力するプログラムを作成する。

## プロンプト

pythonスクリプトで指定された間隔（デフォルト0.5秒）で、指定された回数、
犬の鳴き声を出力するプログラムを作成する。
```

> **ファイル名の読み方：**  
> `r8` = 令和8年（2026年）、`ai` = カテゴリ（手入力）、`0417` = 4月17日、`犬の鳴き声...` = タスク名

---

## Step 1 — get-task.sh でタスクを取得

```bash
bash get-task.sh
```

**実際の出力：**

```
▶ Obsidian Local REST API に接続確認中...
  ✅ 接続成功

▶ タスクフォルダ一覧を取得中 (agentTasks/todo/)...
  ✅ 月別フォルダが見つかりました: 2026-04/

  ✅ 1 件のタスクが見つかりました

========================================
 AIエージェント向けタスク一覧
========================================

========================================
タスクファイル: agentTasks/todo/2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md
タイトル:       犬の鳴き声を出力するプログラムを作成
優先度:         medium
作成日:         2026-04-17
========================================

## 内容
犬の鳴き声を出力するプログラムを作成する。

## プロンプト
pythonスクリプトで指定された間隔（デフォルト0.5秒）で、指定された回数、犬の鳴き声を出力するプログラムを作成する。

========================================
 作業完了後は以下のコマンドでタスクを完了にしてください:
   bash complete-task.sh <yyyy-mm/ファイル名> [成果物のvault内パス ...]
   例（成果物なし）: bash complete-task.sh 2026-04/r8-ai-0417-setup修正.md
   例（成果物あり）: bash complete-task.sh 2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md \
                       agentTasks/_ai_working/2026-04-17/dog-bark.sh

 ℹ️  成果物ファイルの保存方法:
   作業で生成したファイル（スクリプト・コード・レポートなど）は
   Obsidian REST API の PUT で Vault 内の以下のパスに直接保存してください:
     agentTasks/_ai_working/2026-04-17/<ファイル名>

   complete-task.sh が自動で agentTasks/ai_outputs/2026-04-17/ にコピーし、
   _ai_working/ から削除して、タスクファイルに [[Obsidianリンク]] を追記します。
========================================
```

---

## Step 2 — プロンプトに従って成果物を作成し Vault に保存

AIエージェントが `## プロンプト` の指示に従い `dog-bark.py` を作成し、Vault の `_ai_working/` に直接保存します。

> **保存先について：**  
> 成果物は Vault の `agentTasks/_ai_working/yyyy-mm-dd/` に直接保存します。  
> `complete-task.sh` が `ai_outputs/` へのコピーと `_ai_working/` からの削除を自動で行います。

---

## Step 3 — complete-task.sh でタスクを完了・成果物を移動

```bash
bash complete-task.sh \
  "2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md" \
  "agentTasks/_ai_working/2026-04-17/dog-bark.py"
```

**実際の出力：**

```
▶ タスク: 2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md
  移動元: agentTasks/todo/2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md
  移動先: agentTasks/done/2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md
  成果物: agentTasks/_ai_working/2026-04-17/dog-bark.py

▶ タスクを取得中...
  ✅ タスク取得完了

▶ 成果物を ai_outputs/ にコピー中 (agentTasks/ai_outputs/2026-04-17/)...
  ✅ コピー完了: dog-bark.py → agentTasks/ai_outputs/2026-04-17/dog-bark.py (HTTP 204)
  🗑️  削除完了: agentTasks/_ai_working/2026-04-17/dog-bark.py (HTTP 204)

▶ タスクファイルに成果物リンクを追記しました:
  - [[dog-bark.py]]

▶ done フォルダに移動中: agentTasks/done/2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md
  ✅ done フォルダへの書き込み完了 (HTTP 204)
▶ todo フォルダから削除中: agentTasks/todo/2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md
  ✅ todo フォルダから削除完了 (HTTP 204)

✅ タスク完了: 2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md
   agentTasks/todo/2026-04/ → agentTasks/done/2026-04/ に移動しました。
   成果物 → agentTasks/ai_outputs/2026-04-17/ に保存しました。
   Obsidian でタスクファイルを開くと [[リンク]] から成果物を参照できます。
```

---

## Step 4 — 完了後の状態を確認

### Vault のフォルダ構成

```
agentTasks/
├── todo/
│   └── 2026-04/                   ← 空（タスクは done に移動済み）
├── done/
│   └── 2026-04/
│       └── r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md  ← ✅ 完了
├── _ai_working/
│   └── 2026-04-17/                ← 空（成果物は ai_outputs に移動・削除済み）
└── ai_outputs/
    └── 2026-04-17/
        └── dog-bark.py            ← ✅ Vault に保存済み
```

### 完了後のタスクファイル内容

`agentTasks/done/2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md` の内容：

```markdown
---
status: done
priority: medium
created: 2026-04-17
---

# 犬の鳴き声を出力するプログラムを作成

## 内容

犬の鳴き声を出力するプログラムを作成する。

## プロンプト

pythonスクリプトで指定された間隔（デフォルト0.5秒）で、指定された回数、
犬の鳴き声を出力するプログラムを作成する。

## 成果物
- [[dog-bark.py]]
```

変更点：
- `status: todo` → `status: done` に自動更新
- `## 成果物` セクションが追記され `[[dog-bark.py]]` リンクが設定される

---

## Step 5 — Obsidian でリンクを使って成果物を開く

1. Obsidian のファイルエクスプローラーで  
   `agentTasks/done/2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md` を開く

2. `## 成果物` セクションに表示された `[[dog-bark.py]]` をクリック

3. `agentTasks/ai_outputs/2026-04-17/dog-bark.py` が Obsidian 内で開き、コードを確認できる

```
┌──────────────────────────────────────────────┐
│ 完了タスクファイル（done）                    │
│                                              │
│  ## 成果物                                   │
│  - [[dog-bark.py]]  ← ここをクリック         │
│            │                                 │
│            ▼                                 │
│  ai_outputs/2026-04-17/dog-bark.py が開く    │
└──────────────────────────────────────────────┘
```

> **対応ファイル形式：**  
> `.py`・`.sh`・`.md`・`.txt`・`.json` など、テキスト形式のファイルであれば  
> Obsidian 内で内容を表示できます。

---

## opencode への指示プロンプトのコピー用テンプレート

このワークフローを opencode に指示する際は以下のプロンプトをそのままコピーしてご利用ください。

```
get-task.sh を実行して Obsidian の agentTasks/todo から最新のタスクを取得し、
プロンプトに従って作業してください。

作業で生成したファイルは Obsidian REST API の PUT で以下のパスに保存してください:
  agentTasks/_ai_working/<今日の日付 yyyy-mm-dd>/<ファイル名>
  （具体的な保存コマンドは get-task.sh の出力フッターに記載されています）

作業完了後は以下のコマンドでタスクを完了にしてください。

bash complete-task.sh <yyyy-mm/ファイル名> \
  agentTasks/_ai_working/<yyyy-mm-dd>/<成果物ファイル名>

例:
bash complete-task.sh \
  2026-04/r8-ai-0417-犬の鳴き声を出力するプログラムを作成.md \
  agentTasks/_ai_working/2026-04-17/dog-bark.py
```
