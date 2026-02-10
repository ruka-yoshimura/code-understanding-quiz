#!/usr/bin/env bash
# exit on error
set -o errexit

bundle install
bundle exec rails assets:precompile
bundle exec rails assets:clean
bundle exec rails db:migrate

# 必要に応じてシードを投入する場合はコメントを外す
# bundle exec rails db:seed
