# Should match the Ruby version in .ruby-version. The Rails devcontainer images
# lag a patch release or two behind, so this pins the newest published 4.0 image
# (the Gemfile only requires >= 4.0.0, so a patch difference is fine).
ARG RUBY_VERSION=4.0.6
FROM ghcr.io/rails/devcontainer/images/ruby:$RUBY_VERSION
