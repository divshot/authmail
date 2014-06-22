require 'securerandom'

class Account
  ORIGIN_REGEXP = %r{\Ahttps?://[^/]+}
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :active, type: Boolean
  field :admins, type: Array
  field :reply_to, type: String
  field :origins, type: Array, default: []
  field :redirect, type: String
  field :secret, type: String
  field :html_template, type: String
  field :text_template, type: String
  
  field :stripe_id, type: String
  field :card_type, type: String
  field :card_digits, type: String
  
  validates :name, presence: true
  validates :secret, uniqueness: true, presence: true
  validates_format_of :reply_to, with: /\A(.*<)?[a-z0-9+.-]+@[a-z0-9+.-]+>?\z/i, message: 'must be a valid email'
  
  has_many :authentications
  
  before_validation :generate_secret, on: :create
  
  def self.master
    Account.where(secret: ENV['SECRET']).first || Account.create!(
      name: 'AuthMail',
      secret: ENV['SECRET'],
      origins: [ENV['ORIGIN']],
      redirect: ENV['ORIGIN'] + '/',
      admins: ['hello@authmail.co']
    )
  end
  
  def self.with_card
    where(:stripe_id.exists => true, :card_digits.exists => true)
  end
  
  def valid_request?(request)
    origin = request.env['HTTP_ORIGIN'] || request.env['HTTP_REFERER'] || ""
    possible = (origins + [ENV['ORIGIN']])
    $logger.debug "[origin-check] account=#{name} origin=#{request.env['HTTP_ORIGIN']} referer=#{request.env['HTTP_REFERER']} possible=#{possible.join(',')}"
    return false unless origin = origin.match(ORIGIN_REGEXP).try(:[], 0)
    possible.include?(origin)
  end
  
  def has_card?
    stripe_id? && card_digits?
  end
  
  def origins_text=(text)
    self.origins = text.split("\n").map(&:strip)
  end
  
  def origins_text
    origins.join("\n")
  end
  
  def track(*args)
    MixpanelWorker.perform_async('track', admins.first, *args)
  end
  
  protected
  
  def generate_secret
    self.secret ||= SecureRandom.urlsafe_base64(30)
  end
end