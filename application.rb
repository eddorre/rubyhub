require 'rubygems'
require 'sinatra'
require 'datamapper'
require 'lib/models'
require 'rest_client'
require 'logger'

enable :logging

configure do
  Log = Logger.new(STDOUT)
  Log.level = Logger::DEBUG
end

DataMapper.setup(:default, ENV['DATABASE_URL'] || 'sqlite3://my.db')
DataObjects::Sqlite3.logger = DataObjects::Logger.new(STDOUT, 0)
DataMapper.auto_migrate!
# DataMapper.auto_upgrade!

get '/' do
  publisher = Publisher.new(:title => 'foo')
  publisher.save
  @publishers = Publisher.all
  erb :home
end

post '/subscribe' do
  if request.content_type == 'application/x-www-form-urlencoded'
    return_response = SubscriptionRequest.act_on_request(params)
    throw :halt, return_response
  else
    throw :halt, [ 500, "Invalid content type" ]
  end
end



