require 'sinatra'
require "scale_rb"
require './config/config.rb'
require './utils'

get '/' do
  'Hello Darwinia!'
end

get '/crab/stat' do
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
  metadata = JSON.parse(
    File.read(
      config[:metadata][:crab2]
    )
  )

  content_type :json
  metadata.to_json
end

get '/crab/address/:address' do
  # address must presented
  return { code: 1, message: 'address is required' }.to_json unless params[:address]

  if params[:address].length == 42
    return { code: 0, data: { pubkey: "0x#{Address.decode(params[:address], 42, true)}", ss58: params[:address] } }.to_json
  elsif params[:address].length == 66
    raise "Not implemented yet"
  else
    return { code: 1, message: 'address is invalid' }.to_json
  end
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

  metadata = JSON.parse(
    File.read(
      config[:metadata][:crab2]
    )
  )

  if pallet_name == 'AccountMigration' && params[:key1] && params[:key1].start_with?('5')
    params[:key1] = "0x#{Address.decode(params[:key1], 42, true)}"
  end

  key = [params[:key1], params[:key2]].compact.map { |part_of_key| c(part_of_key) }
  storage = ScaleRb::HttpClient.get_storage2(config[:url], pallet_name, storage_name, key, metadata)

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
