# AIエージェント連携タスク管理ワークフロー

Obsidian vault 上でタスクを作成し、AIエージェント（opencode）が REST API 経由でタスクを取得・実行・完了するワークフローの説明です。

---

## ワークフロー全体図

```
┌─────────────────────────────────────────────────────────────┐
│  ユーザー（Obsidian）                                        │
│                                                              │
│  1. タスクを作成                                              │
│     Ctrl+P → 「新規タスク」（QuickAdd + Templater）          │
│     → カテゴリ入力（例: ai）・優先度選択                     │
│     → agentTasks/todo/2026-04/r8-ai-0417-タイトル.md に保存  │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  ユーザー（ターミナル）                                       │
│                                                              │
│  2. opencode を起動して指示する                               │
│     $ opencode                                               │
│     > get-task.sh を実行してタスクを取得し、作業してください   │
└──────────────────────────┬───────────────────────────────────┘
                           │
                           ▼
┌─────────────────────────────────────────────────────────────┐
│  AIエージェント（opencode）                                   │
│                                                              │
│  3. get-task.sh を実行                                       │
│     → Obsidian REST API 経由で agentTasks/todo/<yyyy-mm>/    │
│       を再帰的に検索                                          │
│     → 優先度順（high → medium → low）にタスク一覧を表示      │
│                                                              │
│  4. タスクの「## プロンプト」に従って作業を実行               │
│     → 成果物は REST API PUT で Vault 内の以下に直接保存：     │
│       agentTasks/_ai_working/yyyy-mm-dd/<ファイル名>         │
│                                                              │
│  5. 作業完了後に complete-task.sh を実行                      │
│     bash complete-task.sh <yyyy-mm/ファイル名> \             │
│       [agentTasks/_ai_working/yyyy-mm-dd/<成果物> ...]       │
│     → _ai_working/ から ai_outputs/ にコピー後、削除          │
│     → todo/<yyyy-mm>/ から done/<yyyy-mm>/ へファイルを移動   │
│     → frontmatter の status を done に更新                   │
│     → タスクファイルに [[Obsidianリンク]] を追記              │
└─────────────────────────────────────────────────────────────┘
```

---

## ファイル名の形式

```
r<令和年>-<カテゴリ>-<MMDD>-<タイトル>.md
```

| 部分 | 内容 | 例 |
|---|---|---|
| `r<令和年>` | 令和年号（西暦 - 2018） | `r8`（2026年 = 令和8年） |
| `<カテゴリ>` | タスク作成時に手入力（小文字に自動変換） | `ai`, `dev`, `ops` など |
| `<MMDD>` | 作成日の月日 | `0417`（4月17日） |
| `<タイトル>` | QuickAdd で入力したタスク名 | `setup修正` |

**例:** `r8-ai-0417-setup修正.md`

---

## タスクファイルの構造

```markdown
---
status: todo
priority: high
created: 2026-04-17
---

# r8-ai-0417-setup修正

## 内容
タスクの概要・背景を自由に記述する。

## プロンプト
AIエージェントへの具体的な指示を記述する。
改行や長文も自由に書いてよい。

例：
setup.sh を読んで、Calendar プラグインのバージョンが
1.5.10 に固定されているか確認してください。
固定されていない場合は修正してください。
```

### frontmatter 項目

| フィールド | 値 | 説明 |
|---|---|---|
| `status` | `todo` / `in_progress` / `done` | タスクの状態（完了時に自動更新） |
| `priority` | `high` / `medium` / `low` | 優先度（取得時のソート順に影響） |
| `created` | `YYYY-MM-DD` | 作成日 |

---

## タスクの保存場所

```
~/Documents/osscVault/
└── agentTasks/
    ├── todo/
    │   └── 2026-04/                  ← 当月フォルダ（setup.sh が自動作成）
    │       └── r8-ai-0417-setup修正.md
    ├── in_progress/
    │   └── 2026-04/
    ├── done/
    │   └── 2026-04/                  ← complete-task.sh が自動で移動
    │       └── r8-ai-0417-foobartask.md   ← ## 成果物 リンクが追記される
    ├── _ai_working/
    │   └── 2026-04-17/               ← AIエージェントの作業領域（yyyy-mm-dd 形式）
    │       └── dog-bark.sh           ← 完了後に ai_outputs/ へ移動・削除される
    └── ai_outputs/
        └── 2026-04-17/               ← 成果物の保存場所（yyyy-mm-dd 形式）
            └── dog-bark.sh           ← Obsidian で [[dog-bark.sh]] からリンク可能
```

- 月が変わると `todo/2026-05/` などの新しいフォルダが自動作成される
- 日付が変わると `_ai_working/2026-04-18/`、`ai_outputs/2026-04-18/` が自動作成される（`setup.sh` 再実行で作成）
- 成果物は `.sh`・`.py`・`.md` など任意の形式で保存可能
- `_ai_working/` は一時作業領域。`complete-task.sh` 実行後に自動で削除される

---

## 手動操作手順（Obsidian UI）

### タスクの作成

1. Obsidian を開く
2. `Ctrl+P`（コマンドパレット）を押す
3. 「新規タスク」と入力して選択
4. タスクタイトル（`{{NAME}}`部分）を入力（例: `setup修正`）
5. Templater が起動し以下を順に入力：
   - **カテゴリ**を入力（例: `ai`）→ Enter
   - **優先度**を選択（`high` / `medium` / `low`）
6. ファイルが `agentTasks/todo/2026-04/r8-ai-0417-setup修正.md` として作成される
7. 開いたファイルの `## 内容` と `## プロンプト` を記述する

### タスクの確認

- Obsidian のファイルエクスプローラーで `agentTasks/todo/2026-04/` を開く
- 各ファイルを開いてタスク内容を確認・編集できる

---

## CLI 操作手順（スクリプト）

### 前提条件

- Obsidian が起動していること
- `obsidian-local-rest-api` プラグインが有効化されていること
- `curl`、`jq`、`python3` がインストールされていること

### get-task.sh — タスクの取得

```bash
bash get-task.sh
```

**実行例：**

```
▶ Obsidian Local REST API に接続確認中...
  ✅ 接続成功

▶ タスクフォルダ一覧を取得中 (agentTasks/todo/)...
  ✅ 月別フォルダが見つかりました: 2026-04/

  ✅ 2 件のタスクが見つかりました

========================================
 AIエージェント向けタスク一覧
========================================

========================================
タスクファイル: agentTasks/todo/2026-04/r8-ai-0417-setup修正.md
タイトル:       r8-ai-0417-setup修正
優先度:         high
作成日:         2026-04-17
========================================

## 内容
setup.sh で Calendar プラグインのバージョンが正しく固定されているか確認する。

## プロンプト
setup.sh を読んで Calendar プラグインのインストール処理を確認してください。
バージョンが 1.5.10 に固定されていない場合は修正してください。

========================================
 作業完了後は以下のコマンドでタスクを完了にしてください:
   bash complete-task.sh <yyyy-mm/ファイル名> [成果物のvault内パス ...]
   例（成果物なし）: bash complete-task.sh 2026-04/r8-ai-0417-setup修正.md
   例（成果物あり）: bash complete-task.sh 2026-04/r8-ai-0417-foobartask.md \
                       agentTasks/_ai_working/2026-04-17/dog-bark.sh

 ℹ️  成果物ファイルの保存方法:
   作業で生成したファイル（スクリプト・コード・レポートなど）は
   Obsidian REST API の PUT で Vault 内の以下のパスに直接保存してください:
     agentTasks/_ai_working/2026-04-17/<ファイル名>

   complete-task.sh が自動で agentTasks/ai_outputs/2026-04-17/ にコピーし、
   _ai_working/ から削除して、タスクファイルに [[Obsidianリンク]] を追記します。
========================================
```

### complete-task.sh — タスクの完了

```bash
# 成果物なし
bash complete-task.sh <yyyy-mm/ファイル名>

# 成果物あり（複数指定可・vault 内パスで渡す）
bash complete-task.sh <yyyy-mm/ファイル名> \
  agentTasks/_ai_working/<yyyy-mm-dd>/<成果物1> \
  [agentTasks/_ai_working/<yyyy-mm-dd>/<成果物2> ...]
```

**実行例（成果物あり）：**

```bash
bash complete-task.sh 2026-04/r8-ai-0417-foobartask.md \
  agentTasks/_ai_working/2026-04-17/dog-bark.sh
```

```
▶ タスク: 2026-04/r8-ai-0417-foobartask.md
  移動元: agentTasks/todo/2026-04/r8-ai-0417-foobartask.md
  移動先: agentTasks/done/2026-04/r8-ai-0417-foobartask.md
  成果物: agentTasks/_ai_working/2026-04-17/dog-bark.sh

▶ タスクを取得中...
  ✅ タスク取得完了

▶ 成果物を ai_outputs/ にコピー中 (agentTasks/ai_outputs/2026-04-17/)...
  ✅ コピー完了: dog-bark.sh → agentTasks/ai_outputs/2026-04-17/dog-bark.sh (HTTP 204)
  🗑️  削除完了: agentTasks/_ai_working/2026-04-17/dog-bark.sh (HTTP 204)

▶ タスクファイルに成果物リンクを追記しました:
  - [[dog-bark.sh]]

▶ done フォルダに移動中: agentTasks/done/2026-04/r8-ai-0417-foobartask.md
  ✅ done フォルダへの書き込み完了 (HTTP 204)
▶ todo フォルダから削除中: agentTasks/todo/2026-04/r8-ai-0417-foobartask.md
  ✅ todo フォルダから削除完了 (HTTP 204)

✅ タスク完了: 2026-04/r8-ai-0417-foobartask.md
   agentTasks/todo/2026-04/ → agentTasks/done/2026-04/ に移動しました。
   成果物 → agentTasks/ai_outputs/2026-04-17/ に保存しました。
   Obsidian でタスクファイルを開くと [[リンク]] から成果物を参照できます。
```

**完了後のタスクファイル（done）の例：**

```markdown
---
status: done
priority: medium
created: 2026-04-17
---

# r8-ai-0417-foobartask

## 内容
犬の鳴き声をechoするプログラムを作成する。

## プロンプト
shスクリプトで犬の鳴き声をechoするプログラムを作成して。

## 成果物
- [[dog-bark.sh]]    ← クリックすると Obsidian 内でファイルが開く
```

---

## opencode への指示プロンプト例

opencode を起動後、以下のように指示してください。

### 基本的な指示

```
get-task.sh を実行して Obsidian の agentTasks/todo から最新のタスクを取得し、
プロンプトに従って作業してください。
作業完了後は complete-task.sh <yyyy-mm/ファイル名> を実行してタスクを完了にしてください。
```

### 優先度を指定する場合

```
get-task.sh を実行して high 優先度のタスクだけ対応してください。
作業完了後は complete-task.sh でタスクを完了にしてください。
```

### 確認を挟む場合

```
get-task.sh を実行してタスク一覧を表示し、
作業を始める前に何をするか説明してください。
確認後に作業を開始し、complete-task.sh で完了してください。
```

---

## REST API 直接操作（上級者向け）

スクリプトを使わず REST API を直接叩くこともできます。

### 設定値

| 項目 | 値 |
|---|---|
| エンドポイント | `https://127.0.0.1:27124` |
| APIキー | `$OBSIDIAN_API_KEY`（環境変数から読み込む） |

### 月別フォルダ一覧の取得

```bash
curl -sk \
  -H "Authorization: Bearer <APIキー>" \
  -H "Accept: application/json" \
  "https://127.0.0.1:27124/vault/agentTasks/todo/"
```

### 特定月のタスク一覧の取得

```bash
curl -sk \
  -H "Authorization: Bearer <APIキー>" \
  -H "Accept: application/json" \
  "https://127.0.0.1:27124/vault/agentTasks/todo/2026-04/"
```

### タスクファイルの内容取得

```bash
curl -sk \
  -H "Authorization: Bearer <APIキー>" \
  -H "Accept: text/markdown" \
  "https://127.0.0.1:27124/vault/agentTasks/todo/2026-04/r8-ai-0417-setup修正.md"
```

### タスクファイルの書き込み（作成・更新）

```bash
curl -sk -X PUT \
  -H "Authorization: Bearer <APIキー>" \
  -H "Content-Type: text/markdown" \
  --data-raw "<Markdownコンテンツ>" \
  "https://127.0.0.1:27124/vault/agentTasks/todo/2026-04/<ファイル名>"
```

### タスクファイルの削除

```bash
curl -sk -X DELETE \
  -H "Authorization: Bearer <APIキー>" \
  "https://127.0.0.1:27124/vault/agentTasks/todo/2026-04/<ファイル名>"
```

> **補足：ファイルの移動**  
> REST API にはファイル移動エンドポイントがないため、「新パスへ PUT → 旧パスを DELETE」の2ステップで移動を実現しています。

---

## トラブルシューティング

| 症状 | 原因 | 対処 |
|---|---|---|
| `接続できません` | Obsidian が未起動、またはプラグインが無効 | Obsidian を起動し、`obsidian-local-rest-api` プラグインを有効化する |
| `月別フォルダがありません` | `agentTasks/todo/` 直下に `yyyy-mm` フォルダがない | `setup.sh` を再実行するか、Obsidian で QuickAdd からタスクを作成する |
| `有効なタスクが見つかりませんでした` | 月別フォルダ内に `.md` ファイルがない | Obsidian で QuickAdd からタスクを作成する |
| `ファイルが見つかりません` | パスのタイポ | `get-task.sh` の出力に表示されたファイルパス（`yyyy-mm/ファイル名` 部分）をコピーして使う |
| `HTTP 401` | APIキーが不正 | `obsidian-local-rest-api` の設定からAPIキーを確認する |
| ファイル名がリネームされない | Templater が無効か設定が不足 | Obsidian の設定 → Templater → 「Trigger Templater on new file creation」を有効にする |
