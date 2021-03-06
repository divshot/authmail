class MixpanelWorker
  include Sidekiq::Worker
  
  def perform(method, *args)
    tracker.send(method, *args)
  end
  
  def tracker
    @tracker ||= Mixpanel::Tracker.new(ENV['MIXPANEL_KEY'])
  end
end
