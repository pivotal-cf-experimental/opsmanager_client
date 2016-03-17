#!/usr/bin/env bash

set +e

export LANG=C.UTF-8
export LANGUAGE=C.UTF-8
export LC_ALL=C.UTF-8

cd $(dirname $0)/..

bundle install
bundle exec rspec

