#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
# データベースの初期化とシード投入（一回限りの実行）
bundle exec rails db:schema:load db:seed DISABLE_DATABASE_ENVIRONMENT_CHECK=1
