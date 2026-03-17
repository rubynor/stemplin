web: bundle exec puma -C config/puma.rb
js: yarn build
css: yarn build:css
release: bundle exec rails db:migrate
worker: bundle exec sidekiq -e production -C config/sidekiq.yml
