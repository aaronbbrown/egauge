#!/usr/bin/env bash

bundle check || bundle install

while : ; do
  echo "$(date) Sending solar stats"
  bundle exec ./egaugepull.rb | nc localhost 2003
  sleep 59
done
