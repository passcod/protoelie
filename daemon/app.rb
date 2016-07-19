require 'bundler'
Bundler.require
require './namedom'

configure do
  Namedom.init
end

get '/' do
  content_type :json
  Namedom.all.to_json
end

get '/:domain' do
  content_type :json
  Namedom.new(params[:domain]).to_json
end

put '/:domain' do
  content_type :json
  dom = Namedom.new(params[:domain])
  request.body.rewind
  begin
    data = JSON.parse request.body.read
  rescue JSON::ParserError => e
    return [400, {error: 'Bad JSON in body'}.to_json]
  end
  dom.type = data['type'] if data['type']
  dom.domains = data['domains'] if data['domains']
  if dom.exists?
    res = 202
  else
    res = 201
  end
  dom.save!
  [res, dom.to_json]
end

delete '/:domain' do
  Namedom.new(params[:domain]).delete!
  204
end

get '/:domain/:format' do
  content_type 'application/x-pem-file'
end
