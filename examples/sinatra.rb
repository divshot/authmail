require 'sinatra'
require 'jwt'

AUTHMAIL_LOGIN_URL = 'https://authmail.co/login'
AUTHMAIL_CLIENT_ID = '53a3d382ff69b2e926000001'
AUTHMAIL_SECRET = 'MgCnYsOoggRtnuPF9YkOhbeMxinykjqckIhogaEK'

get '/' do
  "<form action='#{AUTHMAIL_LOGIN_URL}' method='post'><input type='hidden' name='client_id' value='#{AUTHMAIL_CLIENT_ID}'><input type='email' name='email'> <input type='submit'></form>"
end

get '/auth' do
  content_type 'application/json'
  JWT.decode(params[:payload], AUTHMAIL_SECRET).first.to_json
end