require 'securerandom'

class Authentication
  include Mongoid::Document
  include Mongoid::Timestamps::Created
  
  belongs_to :account
  
  field :ref, type: String
  field :email, type: String
  field :status, type: String, default: 'pending'
  field :status_message, type: String
  field :status_updated_at, type: Time
  field :redirect, type: String
  field :expires_at, type: Time
  field :state
  
  
  validates :ref, presence: true
  validates :email, presence: true
  validates :status, inclusion: {in: %w(pending sent opened clicked failed succeeded)}
  validates :redirect, presence: true
  
  validate :redirect_matches_origin
  
  before_validation :generate_uid, :set_expiration, on: :create
  
  def self.active(time = Time.now)
    where(:expires_at.gt => time)
  end
  
  def redirect
    self.redirect?? super : account.redirect
  end
  
  def redirect_domain
    URI.parse(redirect).host
  end
  
  def link
    ENV['ORIGIN'] + "/login/#{ref}"
  end
  
  def message
    @message ||= Message.new(self)
  end
  
  def consumed?
    %w(succeeded failed).include? status
  end
  
  def expired?(time = Time.now)
    expires_at < time
  end
  
  def consume!
    status!(:failed, 'This authentication link has already been used.') and return false if consumed?
    status!(:failed, 'This authentication link has expired.') and return false if expired?
    
    status!(:succeeded, nil)
    true
  end
  
  def status!(status, message = nil)
    self.status = status.to_s
    self.status_message = message
    self.status_updated_at = Time.now
    self.save!
  end
  
  def deliver!
    Message::Worker.perform_async(self.id.to_s)
  end
  
  # whether or not this is the first auth for this email
  def signup?
    account.authentications.where(email: self.email).where(:_id.ne => self.id).empty?
  end
  
  def payload
    JWT.encode({
      aud: account.id,
      sub: self.email,
      exp: 5.minutes.from_now.to_i,
      iat: self.created_at.to_i,
      jti: self.id,
      state: self.state,
      signup: self.signup?
    }, account.secret)
  end
  
  protected
  
  def generate_uid
    new_ref = SecureRandom.urlsafe_base64(10)
    
    generate_ref if Authentication.active.where(ref: new_ref).any?
    self.ref = new_ref
  end
  
  def set_expiration
    self.expires_at = Time.now + 10.minutes
  end
  
  def redirect_matches_origin
    account.origins.each do |origin|
      return if self.redirect.starts_with?(origin + '/')
    end
    errors.add(:redirect, 'must be on a provided origin for this account.')
  end
end