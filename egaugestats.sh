#!/usr/bin/env bash

INTERVAL=1

bundle check || bundle install

while : ; do
  echo "$(date) Sending solar stats"
  bundle exec ./egaugepull.rb | nc localhost 2003
  sleep $INTERVAL 
done
