# 📦 ワークスペース単位の MCP 開発環境

Dev Containers と `docker compose` のどちらからでも同じ初期化フローを使えるように仕立てたテンプレートです。`docker compose up` で立ち上げた場合でも VS Code から接続した場合でも、コンテナ内では `.container-scripts/core/entrypoint.sh` が共通処理を呼び出します。

## 必要な環境
- Codex が利用できるアカウント
- Docker Desktop
- VS Code (Dev Containers 拡張を利用する場合)

## コンテナ起動

```bash
docker compose up -d --build
```

起動後に `docker compose exec app bash` でコンテナに入るか、VS Code の Dev Containers からアタッチしてください。

## スクリプト構成

- `.container-scripts/core/` : Dockerfile とリポジトリ管理の初期化スクリプト群。編集禁止運用を想定。
  - `Dockerfile` : ベース OS のセットアップ（パッケージ導入やユーザー作成など）を一度だけ実行。
  - `entrypoint.sh` : 共有エントリポイント。`.container-home` の同期 → core/user スクリプトの順で実行。
  - `init.sh` : uv の同期、git 設定、ホーム配下の整備など必須処理。
  - `post-start.sh` : pre-commit のインストールや Claude Code テンプレートの起動など。
- `.container-scripts/user/` : ユーザーごとの拡張ポイント (Git ignore 対象)。
  - `init-add.sh` / `post-start-add.sh` : 任意で作成。実行したいコマンドを記述すると core スクリプトの後に呼ばれます。
  - `*.example.sh` : ひな型。

`.container-home` に配置した設定ファイルは、エントリポイントでコンテナの `$HOME` へシンボリックリンクされます。既存ファイルがある場合は `.bak-<timestamp>` に退避してからリンクします。

## Dev Container 設定

`.devcontainer/devcontainer.json` は VS Code 用の設定（拡張機能やポート設定）のみに絞っています。ビルドや初期化ロジックはすべて `compose.yml` 経由で共有されます。

## Git 運用のヒント

- `.container-scripts/core/` の変更を防ぎたい場合、リポジトリ側で pre-commit/pre-push フックを用意して更新を拒否してください。
- ユーザー固有の MCP 追加や CLI の常駐処理は `init-add.sh` / `post-start-add.sh` へ記述し、リポジトリを汚さずにカスタマイズできます。

## 参考

- [解説ブログ](https://zenn.dev/moore_s/articles/mcp-dev-env-with-codex-and-devcontainer)
