require 'json'

class App < Sinatra::Base
  get '/' do
    erb :home
  end
  
  post '/register' do
    Account.create(
      name: params[:name],
      email: params[:email]
    )
  end
  
  post '/login' do
    params.merge! JSON.parse(request.env['rack.input'].read).symbolize_keys if request.content_type == 'application/json'
    @account = Account.find(params[:client_id])
    @authentication = Authentication.create!(account: @account, email: params[:email], redirect: params[:redirect_uri])
    @authentication.deliver!
  end
  
  get '/login/:ref' do
    @authentication = Authentication.find_by_ref(params[:ref])
    if @authentication.consume!
      redirect @authentication.redirect + "?payload=#{@authentication.payload}"
    else
      erb :failure
    end
  end
  
  post '/send' do
    account = Account.from_request(request)
  end
end