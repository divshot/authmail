require File.dirname(__FILE__) + '/config/environment'

require 'honeybadger'
require 'sidekiq/web'

Honeybadger.configure do |config|
  config.api_key = ENV['HONEYBADGER_KEY']
end

map '/sidekiq' do
  use Rack::Auth::Basic, "AuthMail" do |username, password|
    username == 'admin' && password == (ENV['ADMIN_PASSWORD'] || "test")
  end

  run Sidekiq::Web
end

run App