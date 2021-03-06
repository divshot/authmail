APP_ROOT = File.dirname(__FILE__) + '/../'
$:.push APP_ROOT

require 'bundler'
Bundler.require :default, (ENV['RACK_ENV'] || :development).to_sym
Dotenv.load

Mongoid.load!(APP_ROOT + '/config/mongoid.yml')

Logger.send :alias_method, :write, :<<
$logger = Logger.new($stdout)

Stripe.api_key = ENV['STRIPE_SECRET']

$mp = Mixpanel::Tracker.new(ENV['MIXPANEL_API_TOKEN'])

unless ENV['RACK_ENV'] == 'production'
  require 'sidekiq/testing'
  Sidekiq::Testing.inline!
end

if ENV["REDISCLOUD_URL"]
  uri = URI.parse(ENV["REDISCLOUD_URL"])
  $redis = Redis.new(:host => uri.host, :port => uri.port, :password => uri.password)
else
  $redis = Redis.new
end

require 'app/_index'