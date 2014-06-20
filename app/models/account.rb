require 'securerandom'

class Account
  include Mongoid::Document
  include Mongoid::Timestamps
  
  field :name, type: String
  field :active, type: Boolean
  field :admins, type: String
  field :admins_pending, type: Array
  field :reply_to, type: String
  field :origins, type: Array
  field :redirect, type: String
  field :secret, type: String
  field :html_template, type: String
  field :text_template, type: String
  
  validates :name, presence: true
  validates :secret, uniqueness: true, presence: true
  
  has_many :authentications
  
  before_validation :generate_secret, on: :create
  
  def self.master
    Account.find_by_secret(ENV['SECRET']) || Account.create!(
      name: 'AuthMail',
      secret: ENV['SECRET'],
      origins: [ENV['ORIGIN']],
      admins: ['hello@authmail.co']
    )
  end
  
  protected
  
  def generate_secret
    self.secret ||= SecureRandom.urlsafe_base64(20)
  end
end