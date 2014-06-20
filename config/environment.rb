APP_ROOT = File.dirname(__FILE__) + '/../'
$:.push APP_ROOT

require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
Dotenv.load

Mongoid.load!(APP_ROOT + '/config/mongoid.yml')

unless ENV['RACK_ENV'] == 'production'
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
end

require 'app/_index'