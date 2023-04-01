require 'sinatra'

def to_camel(str)
  tmp = str[0].downcase + str[1..]
  splits = tmp.split('_')
  splits[0] + splits[1..].collect(&:capitalize).join
end

get '/' do
  'Hello Darwinia!'
end

get '/crab' do
  result = File.read(File.join(__dir__, 'data.json'))
  result = JSON.parse(result)

  t_list = %w[crab_reserved_in_staking ckton_reserved_in_staking crab_in_deposit]
  if params['t'] && t_list.include?(params['t'])
    content_type :text
    return result[params['t']].to_s
  end

  content_type :json
  {
    code: 0,
    data: result
  }.to_json
end

get '/crab/metadata' do
  content_type :json
  metadata.to_json
end
