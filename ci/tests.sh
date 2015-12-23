#!/usr/bin/env bash

set +e

cd $(dirname $0)/..

bundle install
bundle exec rspec 
