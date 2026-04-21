# obsidian-dev

AIエージェントへの依頼タスクを Obsidian CLI のタスク管理で実施するための、ミニマムセットアップスクリプトを提供します。

---

## obsidianのインストール

ダウンロードとDesktop設定の実施。

```
./install.sh
```

install完了後、Desktopより、obsidianを検索すると出てくるので、obsidianアプリ起動する。

UIに従いValutを作成する。本例では~/Documents/osscVaultに作成することを想定しているが、任意の場所で問題ない。


作成後に日本語設定を行う。

1. ショートカット **Ctrl + ,**（macOS では **Cmd + ,**）で設定を開きます。
2. General -> lang -> 日本

アプリ再起動。

## 環境設定
### obsidianのプラグインインストールと設定

```
./setup.sh ~/Documents/osscVault
```

アプリ再起動すると、プラグインを有効化するかというダイアログが出るので、有効化する。


TODO: 有効化後にperiodic-notesプラグインのjson読み込みに失敗するメッセージが出力される。

### obsidian-cli のインストール

### インストール手順

コマンドラインインターフェース（`obsidian` コマンド）は、Obsidian アプリの設定から「コマンドラインインターフェース」を有効化することで使用できるようになります。`npm install` は不要です。

1. Obsidian アプリを起動します。
2. ショートカット **Ctrl + ,**（macOS では **Cmd + ,**）で設定を開きます。
3. 左メニューから **「Obsidian について」** を選択します。
4. **「高度な設定」** セクションを開きます。
5. **「コマンドラインインターフェース」** の項目を見つけ、トグルを **有効化** します。

有効化後、ターミナルから `obsidian` コマンドが使用できるようになります。

---

## API キーの取得・設定と obsidian-cli の実行手順

`obsidian-cli` は Obsidian の **Local REST API** プラグインを通じて Obsidian を操作します。
以下の手順で API キーを取得し、環境変数に設定してから `obsidian-cli` を実行してください。

### ステップ 1: API キーの取得

1. Obsidian の **Settings** > **Community plugins** で **Local REST API** の歯車アイコン（⚙）をクリックします。
2. **「API Key」** 欄に表示されている文字列をコピーします。

### ステップ 2: 環境変数の設定

取得した API キーを環境変数 `OBSIDIAN_API_KEY` に設定します。
シェルの設定ファイル（`~/.bashrc`、`~/.zshrc` など）に以下を追記して、ターミナル起動時に自動で読み込まれるようにします。

```bash
# ~/.bashrc または ~/.zshrc に追記
export OBSIDIAN_API_KEY="ここに取得したAPIキーを貼り付ける"
```

追記後、設定を反映します。

```bash
# bash の場合
source ~/.bashrc

# zsh の場合
source ~/.zshrc
```

### ステップ 3: obsidian-cli の実行

環境変数が設定されていれば、以下のように `obsidian-cli` コマンドを実行できます。

```bash
# デイリーノートを開く
obsidian daily

```

> **注意:** `OBSIDIAN_API_KEY` が設定されていない場合は、`-apikey` オプションで直接指定することもできます。
> ```bash
> obsidian daily -apikey "your-api-key-here"
> ```

---

## ボルト構成

`setup.sh` を実行すると、以下のディレクトリ構成がボルト直下に自動作成されます。

```
ObsidianNotes/
├── activityJournals/  # ざっくり書き出す用（日次メモ・Calendar プラグインと連携）
├── thoughtSpace/      # がっつり考える用（テーマ別の深掘りメモ）
├── knowledge/         # 見返す用（参照したメモを形式知としてまとめる場所）
├── _templates/        # テンプレートファイル（DailyNotesTemplate.md など）
├── _assets/
│   └── images/        # 画像・PDF などの添付リソース
├── agentTasks/        # AIエージェントへのタスク管理
│   ├── todo/
│   │   └── yyyy-mm/   # 未着手タスク（当月フォルダ）
│   ├── in_progress/
│   │   └── yyyy-mm/   # 作業中タスク
│   ├── done/
│   │   └── yyyy-mm/   # 完了タスク（成果物への [[リンク]] 付き）
│   ├── _ai_working/
│   │   └── yyyy-mm-dd/ # AIエージェントの作業中一時領域（完了後は削除される）
│   └── ai_outputs/
│       └── yyyy-mm-dd/ # 成果物の保存先（AIエージェントが生成したファイル）
└── .obsidian/         # Obsidian 設定・プラグイン（自動生成）
```

### 各ディレクトリの役割

| ディレクトリ | 用途 |
|---|---|
| `activityJournals` | 日次でメモを分けて記録する場所。とにかくまず書き出すための受け皿。Calendar プラグインで日別ファイルを素早く作成できる |
| `thoughtSpace` | 特定のテーマについて深く思考を巡らせるためのメモ置き場。日を跨ぐような深い考察のみを置く |
| `knowledge` | 実際に参照したメモを整理し、形式知として蓄積するための場所 |
| `_templates` | Obsidian の Templates / Daily Notes プラグインが使用するテンプレートファイル |
| `_assets/images` | ノートに貼り付けた画像・PDF などの添付ファイルを一元管理 |
| `agentTasks/todo` | AIエージェントへの未着手タスク。`yyyy-mm` サブフォルダに月別管理 |
| `agentTasks/in_progress` | 作業中タスクの置き場 |
| `agentTasks/done` | 完了タスク。`status: done` に更新され `## 成果物 [[リンク]]` が追記される |
| `agentTasks/_ai_working` | AIエージェントの作業中一時領域（`yyyy-mm-dd` 単位）。`complete-task.sh` 実行後に削除される |
| `agentTasks/ai_outputs` | AIエージェントが生成した成果物の保存先（`yyyy-mm-dd` 単位）。Obsidian の `[[リンク]]` からアクセス可能 |

### 自動生成される Obsidian 設定

`setup.sh` 実行時に `.obsidian/` 配下の設定ファイルも自動で生成されます。

| 設定ファイル | 内容 |
|---|---|
| `app.json` | 新規ノートを現在のフォルダに作成 / 添付ファイルを `_assets/images/` に集約 / Backlinks を有効化 |
| `daily-notes.json` | Daily Notes の保存先を `activityJournals/YYYY/MM/DD/`、テンプレートを `_templates/DailyNotesTemplate.md` に設定 |
| `templates.json` | テンプレートフォルダを `_templates/` に設定 |

---

## おすすめプラグインのセットアップ

以下のスクリプトを実行すると、AIエージェントのタスク管理に適した推奨プラグインを自動でインストール・有効化します。

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
| 5 | **Periodic Notes** | デイリー/ウィークリーノートでのタスク記録 |
| 6 | **Calendar** | カレンダーUIでデイリーノートへ素早くアクセス |
| 7 | **Local REST API** | obsidian-cli から Obsidian を API 経由で操作するための REST API サーバー |

---

## プラグイン選定基準

プラグインは以下の観点に基づいて選定しました。本用途（AIエージェントへの依頼タスクを Obsidian で一元管理）に対して直接的に貢献するものを優先しています。

| 観点 | 選定プラグイン | 理由 |
|---|---|---|
| **① タスク定義・追跡** | Tasks, Dataview | AIエージェントへの依頼をタスクとして記録し、期限・ステータスをクエリで集計する中核機能 |
| **② 入力の効率化** | Templater, QuickAdd | タスク登録テンプレートやホットキーで、依頼内容を素早く定型フォーマットで記録 |
| **③ 時間軸での整理** | Periodic Notes, Calendar | デイリー/ウィークリーノートで、日付ごとのタスク進捗を管理。Calendar UI で素早くナビゲート |
| **④ CLI 連携** | Local REST API | obsidian-cli が Obsidian を API 経由で操作するために必須 |

---

## 利用用途

このセットアップは **AIエージェントへの依頼タスクを Obsidian で一元管理する** ことを目的としています。

- AIエージェントへの依頼内容をノートに記録
- Tasks プラグインでタスクの進捗・期限を追跡
- Dataview でタスクの状態を自動集計・可視化
- Periodic Notes でデイリー/ウィークリーノートにタスクを記録
- Obsidian CLI でスクリプトや外部ツールからタスクを操作

利用する際はdoc配下のmdファイルに詳細を記載しているため、vaultにこのプロジェクトのdocを_docでコピーして利用する。


```
cp -r docs  <path-to-your-vault>/_doc>
```


