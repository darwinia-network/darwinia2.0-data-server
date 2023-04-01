require 'sinatra'
require "scale_rb"
require './utils'

# prepare darwinia metadata
metadata_content = File.read(File.join(__dir__, 'config', 'crab2.json'))
metadata = JSON.parse(metadata_content)
url = 'https://crab-rpc.darwinia.network'

get '/' do
  'Hello Darwinia!'
end

get '/crab/statistic' do
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

# write a action to get substrate pallets data
# Example:
# key is empty:
# /crab/timestamp/now
# /crab/system/number
# /crab/darwinia_staking/reward_points
# /crab/vesting/vesting/
# /crab/deposit/deposits
#
# key has one parts: key1
# /crab/deposit/deposits/0x0a1287977578F888bdc1c7627781AF1cc000e6ab
# /crab/system/block_hash/0
# /crab/bridgeDarwiniaMessages/inboundLanes/0x00000000
#
# key has two parts: key1 & key2
# /crab/assets/account/0/0x0a1287977578F888bdc1c7627781AF1cc000e6ab
# /crab/assets/account/0x1234 -> error
get '/crab/:pallet_name/:storage_name/?:key1?/?:key2?' do
  pallet_name = to_camel params[:pallet_name]
  storage_name = to_camel params[:storage_name]
  
  puts "#{pallet_name}##{storage_name}(#{[params[:key1], params[:key2]].compact.join(", ")})"

  key = [params[:key1], params[:key2]].compact.map { |part_of_key| c(part_of_key) }
  storage = ScaleRb::HttpClient.get_storage2(url, pallet_name, storage_name, key, metadata)

  # if !params[:key1]
  #   storage = ScaleRb::HttpClient.get_storage2(url, pallet_name, storage_name, [], metadata)
  # elsif params[:key1] && !params[:key2]
  #   storage = ScaleRb::HttpClient.get_storage2(url, pallet_name, storage_name, [c(params[:key1])], metadata)
  # elsif params[:key1] && params[:key2]
  #   storage = ScaleRb::HttpClient.get_storage2(url, pallet_name, storage_name, [c(params[:key1]), c(params[:key2])], metadata)
  # end

  content_type :json
  render_json storage
end

error do |e|
  content_type :json
  if e.class == RuntimeError
    { code: 1, message: "#{e.message}" }.to_json
  else
    { code: 1, message: "#{e.class} => #{e.message}" }.to_json
  end
end
