require 'json'
require 'action_view/helpers/date_helper'

class App < Sinatra::Base
  use Rack::Session::Cookie, expire_after: 2592000, secret: ENV['SECRET']
  
  helpers do
    include ActionView::Helpers::DateHelper
    def current_user
      session[:current_user]
    end
  end
  
  def require_login!
    redirect '/' unless current_user
  end
  
  def authenticate!
    return false unless params[:payload]
    begin
      payload = JWT.decode(params[:payload], Account.master.secret).first
      session[:current_user] = payload["sub"]
    rescue JWT::DecodeError
      false
    end
  end
  
  get '/' do
    if current_user || authenticate!
      redirect '/dashboard'
    else
      erb :home
    end
  end
  
  get '/about' do
    redirect '/docs'
  end
  
  get '/docs' do
    erb :docs
  end
  
  get '/dashboard' do
    require_login!
    @accounts = Account.where(admins: current_user)
    erb :dashboard
  end
  
  post '/accounts' do
    require_login!
    @account = Account.new(params[:account].merge(admins: [current_user]))
    if @account.save
      redirect "/accounts/#{@account.id}"
    else
      redirect :back
    end
  end
  
  get '/accounts/:id' do
    require_login!
    @account = Account.where(admins: current_user).first
    @authentications = @account.authentications.limit(50)
    erb :account
  end
  
  post '/login' do
    params.merge! JSON.parse(request.env['rack.input'].read).symbolize_keys if request.content_type == 'application/json'
    @account = Account.find(params[:client_id])
    
    if @account.valid_request?(request)
      @authentication = Authentication.create!(account: @account, email: params[:email], redirect: params[:redirect_uri], state: params[:state])
      @authentication.deliver!
      erb :login, layout: :bare
    else
      erb :failure, layout: :bare
    end
  end
  
  get '/login/:ref' do
    @authentication = Authentication.where(ref: params[:ref]).first
    
    if @authentication.consume!
      redirect @authentication.redirect + "?payload=#{@authentication.payload}"
    else
      erb :failure
    end
  end
  
  get '/logout' do
    session.destroy
    redirect '/'
  end
  
  post '/send' do
    account = Account.from_request(request)
  end
end