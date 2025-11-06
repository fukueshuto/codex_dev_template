# **📦 ワークスペース単位の MCP 開発環境**

Dev Containers と docker compose のどちらからでも同じ初期化フローを使えるように仕立てたテンプレートです。docker compose up で立ち上げた場合でも VS Code から接続した場合でも、コンテナ内では .container-scripts/core/entrypoint.sh が共通処理を呼び出します。

## **必要な環境**

* Codex が利用できるアカウント（各種 API キー）
* Docker Desktop
* VS Code (Dev Containers 拡張機能)

## **使い方**

### **1\. 設定ファイルの準備**

この環境では、.container-home ディレクトリ配下のファイルが、コンテナ内のホームディレクトリ ($HOME) にシンボリックリンクされます。

まず、設定ファイルのサンプルをコピーして、ご自身の API キーなどを設定してください。

```bash
# このコマンドはホストOS（あなたのPC）で実行します
cp .container-home/.codex/config.example.toml .container-home/.codex/config.toml
```

コピーした .container-home/.codex/config.toml を開き、`[mcp_servers.context7]` などの `YOUR_APIKEY` を実際のキーに書き換えてください。

（.container-home 配下は .gitignore されているため、config.toml やその他のシークレットファイルを誤ってコミットする心配はありません。）

### **2\. コンテナの起動**

以下の2通りの方法があります。

#### **A: VS Code Dev Containers で起動 (推奨)**

1. VS Code でこのリポジトリのフォルダを開きます。
2. 左下の緑色の \>\< アイコンをクリックし、Reopen in Container (または「コンテナーで再度開く」) を選択します。
3. コンテナのビルドと起動が自動的に完了し、VS Code がコンテナに接続されます。

#### **B: Docker Compose CLI で起動**

```bash
# ビルドしてバックグラウンドで起動
docker compose up -d --build

# コンテナに入る
docker compose exec app bash
```

### **3\. 動作確認**

コンテナに入ったら、init.sh によって追加されたエイリアスや、post-start.sh によって起動した MCP サーバーが動作しているか確認できます。

```bash
# エイリアスの確認 (ll や py などが使えればOK)
$ ll
total 20
drwxr-xr-x 1 vscode vscode 4096 Nov  6 10:30 .
drwxr-xr-x 1 root   root   4096 Nov  6 10:28 ..
lrwxrwxrwx 1 vscode vscode   41 Nov  6 10:30 .codex -> /workspace/.container-home/.codex
...

# MCPサーバーの確認 (claude CLI が serena を認識していればOK)
$ claude mcp list
serena
```

## **スクリプト構成**

* .container-scripts/core/ : Dockerfile とリポジトリ管理の初期化スクリプト群。編集禁止運用を想定。
  * Dockerfile : ベース OS のセットアップ（パッケージ導入やユーザー作成など）を一度だけ実行。
  * entrypoint.sh : 共有エントリポイント。.container-home の同期 → core/user スクリプトの順で実行。
  * init.sh : uv の同期、git 設定、ホーム配下の整備など必須処理。
  * post-start.sh : pre-commit のインストールや MCP サーバーの起動など。
* .container-scripts/user/ : ユーザーごとの拡張ポイント (Git ignore 対象)。
  * init-add.sh / post-start-add.sh : 任意で作成。実行したいコマンドを記述すると core スクリプトの後に呼ばれます。
  * \*.example.sh : ひな型。

.container-home に配置した設定ファイルは、エントリポイントでコンテナの $HOME へシンボリックリンクされます。

## **Git 運用のヒント**

* .container-scripts/core/ の変更を防ぎたい場合、リポジトリ側で pre-commit/pre-push フックを用意して更新を拒否してください。（init.sh に \--no-verify を禁止するエイリアスが仕込まれています）
* ユーザー固有の MCP 追加や CLI の常駐処理は init-add.sh / post-start-add.sh へ記述し、リポジトリを汚さずにカスタマイズできます。

## **経緯と謝辞**

このテンプレートは、[zenn.dev のこちらの記事](https://zenn.dev/moore_s/articles/mcp-dev-env-with-codex-and-devcontainer) で紹介されている「Codex と DevContainer でいい感じの MCP 開発環境を作る」という発想をベースに作成されています。素晴らしいアイデアを公開してくださった作者様に感謝します。

元記事の「Dev Containers と Docker Compose のロジックを共通化する」という中核的なアイデアを踏襲しつつ、このリポジトリでは以下の点を変更・拡張しています。

* **スクリプトの責務分離:** 共通基盤 (core) とユーザーカスタマイズ (user) を明確に分離し、リポジトリを汚さずに個別の設定を追加できるようにしました。
* **.container-home による設定管理:** API キーなどのシークレット情報や . から始まる設定ファイル群を、プロジェクトルートから隔離し、安全に管理できるようにしました。（.gitignore で保護されています）
* **Python 環境の刷新:** uv をベースとした環境構築 (uv sync) やエイリアスを導入し、pre-commit のインストールも自動化しました。
* **MCP の汎用化:** Codex 以外の MCP (Serena など) の自動起動にも対応し、より汎用的な MCP 開発テンプレートを目指しています。
