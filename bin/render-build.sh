#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate

# シードデータの投入（初回デプロイ時のみ実行、2回目以降はコメントアウト）
bundle exec rails db:seed
