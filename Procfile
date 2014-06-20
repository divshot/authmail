web: bundle exec puma -C config/puma.rb
worker: bundle exec sidekiq -c 10 -e config/environment.rb
console: bundle exec racksh