# obsidian-dev

AIエージェントへの依頼タスクを Obsidian CLI のタスク管理で実施するための、ミニマムセットアップスクリプトを提供します。

---

## obsidian-cli のインストール

### 前提条件

- [Node.js](https://nodejs.org/) v16 以上
- npm v7 以上
- [Obsidian](https://obsidian.md/) デスクトップアプリ（インストール済み）
- `curl`（プラグインのダウンロードに使用）
- `jq`（JSON 処理に使用）— macOS: `brew install jq` / Ubuntu: `sudo apt install jq`

### インストール手順

```bash
# obsidian-cli をグローバルインストール
npm install -g obsidian-cli
```

インストール後、バージョン確認で動作を確認します。

```bash
obsidian --version
```

---

## おすすめプラグインのセットアップ

以下のスクリプトを実行すると、AIエージェントのタスク管理に適した推奨プラグイン（最大10個）を自動でインストール・有効化します。

```bash
# Obsidian ボルトのパスを指定してセットアップスクリプトを実行
bash setup.sh /path/to/your/vault
```

> **例:** ボルトが `~/Documents/MyVault` にある場合
> ```bash
> bash setup.sh ~/Documents/MyVault
> ```

---

## インストールされるプラグイン一覧

AIエージェントへのタスク管理に特化した以下のプラグインをインストール・有効化します。

| # | プラグイン名 | 用途 |
|---|---|---|
| 1 | **Tasks** | タスクの作成・追跡・期限管理 |
| 2 | **Dataview** | タスクやノートをクエリで集計・表示 |
| 3 | **Templater** | タスク作成用テンプレートの自動化 |
| 4 | **QuickAdd** | ショートカットからタスクを素早く追加 |
| 5 | **Shell Commands** | Obsidian 内から外部スクリプト・AIエージェントを呼び出し |
| 6 | **Periodic Notes** | デイリー/ウィークリーノートでのタスク記録 |
| 7 | **Calendar** | カレンダーからデイリーノートへ素早くアクセス |
| 8 | **Tag Wrangler** | タスクカテゴリのタグ一括管理 |
| 9 | **Obsidian Git** | タスクノートのバージョン管理・自動バックアップ |
| 10 | **Advanced Tables** | タスクリストを表形式で見やすく管理 |

---

## プラグイン選定基準

プラグインは以下の **5つの観点** に基づいて選定しました。本用途（AIエージェントへの依頼タスクを Obsidian で一元管理）に対して直接的に貢献するものを優先しています。

| 観点 | 選定プラグイン | 理由 |
|---|---|---|
| **① タスク定義・追跡** | Tasks, Dataview | AIエージェントへの依頼をタスクとして記録し、期限・ステータスをクエリで集計する中核機能 |
| **② 入力の効率化** | Templater, QuickAdd | タスク登録テンプレートやホットキーで、依頼内容を素早く定型フォーマットで記録 |
| **③ AIエージェント・CLI 連携** | Shell Commands | Obsidian 内からシェルスクリプトや AI CLI（例: `claude`, `gh copilot`）を直接実行し、タスクの自動化を実現 |
| **④ 時間軸での整理** | Periodic Notes, Calendar | デイリー/ウィークリーノートとカレンダーで、日付ごとのタスク進捗を管理 |
| **⑤ データ保全・分類** | Tag Wrangler, Obsidian Git, Advanced Tables | タグ分類・バージョン管理・表形式表示で、タスクノートの整理と履歴管理を実現 |

> **選定から外したプラグイン例**
> - **Kanban**: 視覚的な手動ドラッグ操作が中心で CLI/自動化との親和性が低いため非採用（`Tasks` + `Dataview` のクエリで代替可能）

---

## 利用用途

このセットアップは **AIエージェントへの依頼タスクを Obsidian で一元管理する** ことを目的としています。

- AIエージェントへの依頼内容をノートに記録
- Tasks プラグインでタスクの進捗・期限を追跡
- Dataview でタスクの状態を自動集計・可視化
- Shell Commands プラグインで AI CLI（`claude`、`gh copilot` など）を Obsidian 内から直接実行
- Obsidian Git でタスクノートを自動バックアップ・履歴管理
- Obsidian CLI でスクリプトや外部ツールからタスクを操作
