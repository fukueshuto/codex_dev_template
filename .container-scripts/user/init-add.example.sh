#!/bin/bash
# 任意の初期化コマンドをここに記述してください。
# このファイルを `init-add.sh` にコピーし、実行権限を付与すると
# コンテナ起動時に `.container-scripts/core/init.sh` の後で実行されます。

# 例: 追加パッケージをインストール（初回のみ）
# FLAG_FILE=/var/local/my-init-add.flag
# if [ ! -f "$FLAG_FILE" ]; then
#     sudo apt-get update
#     sudo apt-get install -y your-package
#     sudo touch "$FLAG_FILE"
# fi
