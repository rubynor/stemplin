web: bundle exec puma -C config/puma.rb
js: yarn build
css: yarn build:css
release: bundle exec rails db:migrate
worker: bundle exec sidekiq -C config/sidekiq.yml
