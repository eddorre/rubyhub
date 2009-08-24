class Publisher
  include DataMapper::Resource
  property :id, Serial
  property :title, String
  property :created_at, DateTime
  property :updated_at, DateTime
end

class Subscriber
  include DataMapper::Resource
  property :id, Serial
  property :subscriber_url, String
  property :topic, String
  property :subscription_mode, String
  property :verify_token, String
  property :verified, Boolean, :default => false
  property :lease_seconds, Integer
  property :lease_expiration, DateTime
  property :created_at, DateTime
  property :updated_at, DateTime
  
  def lease_has_expired?
    self.lease_expiration < Date.Today ? true : false
  end
end

class SubscriptionRequest
  def initialize(args)
    @hub_mode = args['hub.mode']
    @callback = args['hub.callback']
    @topic = args['hub.topic']
    @verify = args['hub.verify']
    @verify_token = args['hub.verify_token']
    @lease_seconds = args['hub.lease_seconds'].to_i
    @lease_seconds = 2592000 if @lease_seconds == 0
  end
  
  def self.act_on_request(params)
    validation = params_validation(params)
    unless validation == true
      return validation
    else
      subscription = self.new(params)
      subscription.process
    end
  end
  
  def process
    if @hub_mode == 'subscribe'
      if @verify == 'async'
        subscriber = Subscriber.new(:subscriber_url => @callback, :topic => @topic, 
        :subscription_mode => 'subscribe', :verify_token => @verify_token, 
        :lease_seconds => @lease_seconds,
        :lease_expiration => Time.now + @lease_seconds)
        if subscriber.save
          return [ 202, "Accepted" ]
        else
          return [ 500, "An unknown error has occurred. Please try again." ]
        end
      else
        # RestClient here
      end
    elsif @hub_mode == 'unsubscribe'
      if @verify == 'async'
        if subscriber = Subscriber.first(:subscriber_url => @callback, :topic => @topic)
          subscriber.update_attributes(:subscription_mode => 'unsubscribe', :verified => false)
          return [ 202, "Accepted" ]
        else
          [ 404, "No Content" ]
        end
      else
        # RestClient here
      end
    end
  end
      
  def self.params_validation(params)
    return [ 500, "Invalid hub.mode | use hub.mode={subscribe|unsubscribe}" ] if not params['hub.mode'] or not [ 'subscribe', 'unsubscribe'].include?(params['hub.mode'])
    return [ 500, "Invalid hub.verify | use hub.verify={async|sync}" ] if not params['hub.verify'] or not [ 'async', 'sync' ].include?(params['hub.verify'])
    return [ 500, "Invalid lease time | lease time in seconds must be a positive number"] if params['hub.lease_seconds'].to_i < 0
    return true
  end
end