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
    render(@html_template)
  end
  
  def render(template)
    template.call(
      name: account.name, 
      domain: authentication.redirect_domain, 
      link: authentication.link
    )
  end
  
  def mail_config
    case ENV['RACK_ENV']
    when 'development'
      {via: LetterOpener::DeliveryMethod, via_options: APP_ROOT + '/tmp/letter_opener'}
    when 'test'
      {via: :test}
    else
      {}
    end
  end
  
  def deliver!
    Pony.mail({
      to: authentication.email,
      from: 'AuthMail <login@authmail.co>',
      subject: "Login to #{account.name}",
      body: text_body,
      html_body: html_body
    }.merge(mail_config))
  end
  
  class Worker
    include Sidekiq::Worker
    
    def perform(authentication_id)
      Authentication.find(authentication_id).message.deliver!
    end
  end
end