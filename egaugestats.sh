#!/usr/bin/env bash

bundle check || bundle install

while : ; do
  echo "$(date) Sending solar stats"
  ruby egaugepull.rb | nc localhost 2003
  sleep 60
done
