#!/bin/sh

set -e
gem install rubocop 
gem install rubocop-rspec
gem install rubocop-performance 
gem install rubocop-rails 
gem install bundler
echo "running rubocop"
ruby /action/lib/performer.rb
