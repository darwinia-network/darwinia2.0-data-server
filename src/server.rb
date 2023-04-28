require "sinatra"
require "scale_rb"
require "yaml"
require "eth"
require "json"
include Eth

require_relative "../config/config.rb"
require_relative "./utils"
require_relative "./storage"
require_relative "./account"

config = get_config

get "/" do
  "Hello Darwinia!"
end

##############################################################################
# Darwinia & Crab's supplies
##############################################################################
get "/supply/ring" do
  network = (params["network"] ||= "darwinia").downcase
  if not %w[darwinia crab].include?(network)
    raise_with(
      404,
      "network #{network} not found, only `darwinia` and `crab` are supported",
    )
  end

  result = File.read("./data/#{network}-supplies.json")
  result = JSON.parse(result)

  if params["t"]
    content_type :text
    t = to_camel(params["t"])
    if %w[totalSupply circulatingSupply maxSupply].include?(t)
      return result["ringSupplies"][t].to_s
    end
  end

  content_type :json
  { code: 0, data: result["ringSupplies"] }.to_json
end

get "/supply/kton" do
  network = (params["network"] ||= "darwinia").downcase
  if not %w[darwinia crab].include?(network)
    raise_with(
      404,
      "network #{network} not found, only `darwinia` and `crab` are supported",
    )
  end

  result = File.read("./data/#{network}-supplies.json")
  result = JSON.parse(result)

  if params["t"]
    content_type :text
    t = to_camel(params["t"])
    if %w[totalSupply circulatingSupply maxSupply].include?(t)
      return result["ktonSupplies"][t].to_s
    end
  end

  content_type :json
  { code: 0, data: result["ktonSupplies"] }.to_json
end

get "/seilppuswithbalances" do
  network = (params["network"] ||= "darwinia").downcase
  if not %w[darwinia crab].include?(network)
    raise_with(
      404,
      "network #{network} not found, only `darwinia` and `crab` are supported",
    )
  end

  content_type :json
  File.read("./data/#{network}-supplies.json")
end

##############################################################################
# Crab
##############################################################################
get "/crab/address/:address" do
  content_type :json
  # address must presented
  unless params[:address]
    return { code: 1, message: "address is required" }.to_json
  end

  if params[:address].length == 48
    return(
      {
        code: 0,
        data: {
          pubkey: "0x#{Address.decode(params[:address], 42, true)}",
          ss58: params[:address],
        },
      }.to_json
    )
  elsif params[:address].length == 66
    raise "Not implemented yet"
  else
    return { code: 1, message: "address is invalid" }.to_json
  end
end

##############################################################################
# Pangolin
##############################################################################
get "/pangolin/templates/:filename" do
  content_type :yaml

  # check the file exists, and then render with 404
  file = File.join("./templates", "#{params[:filename]}")
  return 404 unless File.exist? file
  File.read(file)
end

get "/pangolin/templates" do
  # get file list in templates folder
  files = Dir.entries("./templates").select { |f| f.end_with?(".yml") }
  content_type :json
  { code: 0, data: files }.to_json
end

post "/pangolin/versioned_xcm" do
  metadata = JSON.parse(File.read(config[:metadata][:pangolin]))
  registry = Metadata.build_registry(metadata)

  # Find portable type id of VersionedXcm.
  # We just need to find type id of `PolkadotXcm.Execute`'s first param.
  call_type = Metadata.get_call_type("PolkadotXcm", "Execute", metadata)
  versioned_xcm_type_id = call_type._get(:fields).first._get(:type)

  # encode the value from request body
  value = JSON.parse(YAML.load(request.body.read, aliases: true).to_json)
  bytes = PortableCodec.encode(versioned_xcm_type_id, value, registry)

  content_type :json
  { code: 0, data: bytes.to_hex }.to_json
end

post "/pangolin/encode_transact_call" do
  ethereum_contract = params[:ethereum_contract]
  message = params[:message]
  raise "pangolin_hub is null" if params[:pangolin_hub].nil?
  pangolin_hub =
    (
      params[:pangolin_hub]
    ).strip

  puts "pangolin_hub: #{pangolin_hub}"
  # get market fee from pangolin hub
  fee =
    ScaleRb::HttpClient.json_rpc_call(
      config[:pangolin_rpc],
      "eth_call",
      { data: "0xddca3f43", gas: "0x5b8d80", to: pangolin_hub },
      "latest",
    )
  fee = PortableCodec.u256(fee.to_i(16))

  # calculate the call data of `send(address,bytes)` function of pangolin hub
  data_of_send_hex = "0xc89acc86#{
    Util.bin_to_hex(
      Abi.encode(
        ["address", "bytes"], 
        [
          ethereum_contract,
          Util.hex_to_bin(message)
        ]
      )
    )
  }"
  data_of_send = data_of_send_hex.to_bytes

  transact_call = {
    pallet_name: "EthereumXcm",
    call_name: "Transact",
    call: [
      {
        transact: {
          xcm_transaction: {
            V2: {
              gas_limit: PortableCodec.u256(600_000),
              action: {
                Call: pangolin_hub.to_bytes,
              },
              value: fee,
              input: data_of_send,
              access_list: "None",
            },
          },
        },
      },
      [],
    ],
  }

  metadata = JSON.parse(File.read(config[:metadata][:pangolin]))
  encoded_call = Metadata.encode_call(transact_call, metadata)
  transact_call_hex = encoded_call.to_hex

  # find the data_of_send begin and end index in encoded_call
  data_of_send_begin_index = transact_call_hex.index(data_of_send_hex[2..])
  data_of_send_end_index = data_of_send_begin_index + data_of_send.length * 2

  
  
  render_json({
    ethereum_xcm_transact_call: transact_call_hex,
    hub_send: data_of_send_hex,
    send_in_transact: [data_of_send_begin_index, data_of_send_end_index]
  })
end

##############################################################################
# General
##############################################################################
get "/:network/metadata" do
  network = params[:network].downcase
  if not %w[darwinia crab pangolin].include?(network)
    raise_with 404,
               "network #{network} not found, only `darwinia`, `crab` and `pangolin` are supported"
  end
  metadata = JSON.parse(File.read(config[:metadata][network.to_sym]))

  content_type :json
  metadata.to_json
end

get "/:network/accounts/:address" do
  network = network = params[:network].downcase
  if not %w[darwinia crab pangolin].include?(network)
    raise_with 404,
               "network #{network} not found, only `darwinia`, `crab` and `pangolin` are supported"
  end

  metadata = JSON.parse(File.read(config[:metadata][network.to_sym]))
  rpc = config["#{network}_rpc".to_sym]

  info = get_account_info(rpc, metadata, params[:address])

  render_json info
end

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
get "/:network/:pallet_name/:storage_name/?:key1?/?:key2?" do
  network = network = params[:network].downcase
  if not %w[darwinia crab pangolin].include?(network)
    raise_with 404,
               "network #{network} not found, only `darwinia`, `crab` and `pangolin` are supported"
  end

  metadata = JSON.parse(File.read(config[:metadata][network.to_sym]))
  rpc = config["#{network}_rpc".to_sym]

  storage =
    get_storage(
      rpc,
      metadata,
      params[:pallet_name],
      params[:storage_name],
      params[:key1],
      params[:key2],
    )

  render_json storage
end

##############################################################################
# Exception Handling
##############################################################################
def raise_with(status, message)
  content_type :json
  ret = { code: 1, message: "#{message}" }.to_json
  halt status, ret
end

error do |e|
  content_type :json
  if e.class == RuntimeError
    { code: 1, message: "#{e.message}" }.to_json
  else
    { code: 1, message: "#{e.class} => #{e.message}" }.to_json
  end
end
