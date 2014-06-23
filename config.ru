require File.dirname(__FILE__) + '/config/environment'

require 'sidekiq/web'
map '/sidekiq' do
  use Rack::Auth::Basic, "AuthMail" do |username, password|
    username == 'admin' && password == (ENV['ADMIN_PASSWORD'] || "test")
  end

  run Sidekiq::Web
end

run App