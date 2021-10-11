#!/bin/sh

set -e
gem install rubocop 
gem install rubocop-rspec
gem install rubocop-performance 
gem install rubocop-rails 
echo "running rubocop"
ruby /action/lib/performer.rb
