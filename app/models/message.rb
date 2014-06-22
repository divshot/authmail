class Message
  attr_reader :authentication, :account
  
  DEFAULT_HTML_TEMPLATE = File.read(APP_ROOT + '/app/mail/login.html.handlebars')
  DEFAULT_TEXT_TEMPLATE = File.read(APP_ROOT + '/app/mail/login.txt.handlebars')
  
  def initialize(authentication)
    @authentication = authentication
    @account = authentication.account
    @hbs ||= Handlebars::Context.new
  end
  
  def text_body
    @text_template ||= @hbs.compile(account.text_template || DEFAULT_TEXT_TEMPLATE)
    render(@text_template)
  end
  
  def html_body
    @html_template ||= @hbs.compile(account.html_template || DEFAULT_HTML_TEMPLATE)
    render(@html_template) + "\n\n<img src='#{ENV['ORIGIN']}/track/#{authentication.ref}/opened.gif' width='1' height='1'>"
  end
  
  def render(template)
    template.call(
      name: account.name, 
      domain: authentication.redirect_domain, 
      link: authentication.link
    )
  end
  
  def mail_config
    if ENV['MANDRILL_USERNAME']
      {
        via: :smtp,
        via_options: {
          :port =>           '587',
          :address =>        'smtp.mandrillapp.com',
          :user_name =>      ENV['MANDRILL_USERNAME'],
          :password =>       ENV['MANDRILL_APIKEY'],
          :domain =>         'heroku.com',
          :authentication => :plain
        }
      }
    else
      {via: :test}
    end
  end
  
  def deliver!
    Pony.mail({
      to: authentication.email,
      from: "#{account.name} <login@authmail.co>",
      reply_to: account.reply_to?? account.reply_to : "#{account.name} <login@authmail.co>",
      subject: "Your login link for #{account.name}",
      body: text_body,
      html_body: html_body
    }.merge(mail_config))
    authentication.status!(:sent)
  end
  
  class Worker
    include Sidekiq::Worker
    
    def perform(authentication_id)
      Authentication.find(authentication_id).message.deliver!
    end
  end
end