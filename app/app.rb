require 'json'
require 'action_view/helpers/date_helper'
require 'erubis'

class App < Sinatra::Base
  use Rack::Session::Cookie, expire_after: 2592000, secret: ENV['SECRET']
  use Rack::MethodOverride
  
  set :erb, :escape_html => true
  
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
  
  get '/faq' do
    erb :faq
  end
  
  get '/docs' do
    erb :docs
  end
  
  get '/support' do
    erb :support
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
    @account = Account.where(admins: current_user).find(params[:id])
    @authentications = @account.authentications.recent.limit(50)
    @tab = :activity
    erb :account
  end
  
  put '/accounts/:id' do
    require_login!
    @account = Account.where(admins: current_user).find(params[:id])
    if @account.update_attributes(params[:account])
      redirect "/accounts/#{@account.id}"
    else
      @tab = :settings
      @error = @account.errors.full_messages.join(", ")
      erb :settings
    end
  end
  
  get '/accounts/:id/billing' do
    require_login!
    @account = Account.where(admins: current_user).find(params[:id])
    @tab = :billing
    
    if @account.has_card?
      erb :club_member
    else
      erb :billing
    end
  end
  
  get '/accounts/:id/settings' do
    require_login!
    @account = Account.where(admins: current_user).find(params[:id])
    @tab = :settings
    erb :settings
  end
  
  post '/accounts/:id/card' do
    require_login!
    @account = Account.where(admins: current_user).find(params[:id])
    
    begin
      if @account.stripe_id?
        customer = Stripe::Customer.retrieve(@account.stripe_id)
        customer.card = params[:card]
        customer.save
      else
        customer = Stripe::Customer.create(
          email: current_user,
          description: @account.name,
          card: params[:card]
        )
      end

      card = customer.cards.data.first
      @account.update_attributes(stripe_id: customer.id, card_type: card.brand, card_digits: card.last4)
      redirect "/accounts/#{@account.id}/billing"
  
    rescue Stripe::CardError => e
      body = e.json_body
      err  = body[:error]
      @error = "<b>Card Issue:</b> #{err[:message]}"
      erb :billing
    rescue Stripe::InvalidRequestError => e
      @error = "There was a problem capturing your card information. Please try again."
      erb :billing
    rescue Stripe::StripeError => e
      @error = "Something went wrong while processing your request. Please <a href='mailto:hello@authmail.co'>contact support</a>."
      erb :billing
    end
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
  
  get '/track/:ref/opened.gif' do
    @authentication = Authentication.where(ref: params[:ref]).first
    @authentication.status!(:opened) if @authentication.try(:status) == 'sent'
    
    content_type 'image/gif'
    Base64.decode64 'R0lGODlhAQABAIABAP///wAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw=='
  end
  
  get '/__testrender' do
    Account.master.authentications.new(email: 'test@example.com').message.html_body
  end
  
  get '/logout' do
    session.destroy
    redirect '/'
  end
  
  post '/send' do
    account = Account.from_request(request)
  end
end