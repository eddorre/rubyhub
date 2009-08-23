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
  property :verify_token, String
  property :active, Boolean, :default => false
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
    @lease_seconds = args['hub.lease_seconds']
  end
  
  def self.act_on_request(params)
    validation = params_validation(params)
    unless validation == true
      return validation
    else
      case params['hub.mode']
        when 'subscribe' : subscribe
        when 'unsubscribe' : unsubscribe
      end
    end
  end
  
  def self.subscribe
    [ 204, "No Content" ]
  end
  
  def self.unsubscribe
    [ 204, "No Content" ]
  end
  
  def self.params_validation(params)
    return [ 500, "Invalid hub.mode | use hub.mode={subscribe|unsubscribe}" ] if not params['hub.mode'] or not [ 'subscribe', 'unsubscribe'].include?(params['hub.mode'])
    return [ 500, "Invalid hub.verify | use hub.verify={async|sync}" ] if not params['hub.verify'] or not [ 'async', 'sync' ].include?(params['hub.verify'])
    return true
  end
end