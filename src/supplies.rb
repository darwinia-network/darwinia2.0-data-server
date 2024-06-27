require 'scale_rb'
require 'eth'
require 'json'
include Eth
require_relative 'supply/ring'
require_relative 'supply/kton'
require_relative './utils'
require_relative 'account'

def calc_ring_supply(ethereum_rpc, darwinia_rpc, metadata)
  darwinia_client = Eth::Client::Http.new(darwinia_rpc)
  ethereum_client = Eth::Client::Http.new(ethereum_rpc)

  ##########################
  # total issuance
  ##########################
  total_issuance = Supply::Ring.get_total_insurance(darwinia_rpc, metadata)
  puts "total_issuance: #{total_issuance}"

  ##########################
  # reserves
  ##########################
  # 1. darwinia:0x081cbab52e2dBCd52F441c7ae9ad2a3BE42e2284
  darwinia_0x081c = darwinia_client.eth_get_balance('0x081cbab52e2dBCd52F441c7ae9ad2a3BE42e2284')['result'].to_i(16).to_f / 10**18
  puts "darwinia_0x081c: #{darwinia_0x081c}"

  # 2. darwinia:0x6d6f646c64612f74727372790000000000000000
  darwinia_0x6d6f = darwinia_client.eth_get_balance('0x6d6f646c64612f74727372790000000000000000')['result'].to_i(16).to_f / 10**18
  puts "darwinia_0x6d6f: #{darwinia_0x6d6f}"

  ##########################
  # circulating supply
  ##########################
  circulating_supply = total_issuance - (darwinia_0x081c + darwinia_0x6d6f).to_i
  puts "circulating_supply: #{circulating_supply}"

  {
    totalSupply: total_issuance,
    circulatingSupply: circulating_supply,
    maxSupply: 10_000_000_000
  }
end

def calc_kton_supply(rpc, metadata)
  total_issuance = Supply::Kton.get_kton_total_insurance(rpc, metadata)
  puts "kton total_issuance: #{total_issuance}"

  {
    totalSupply: total_issuance,
    circulatingSupply: total_issuance,
    maxSupply: total_issuance
  }
end

def calc_supply(ethereum_rpc, darwinia_rpc, metadata)
  {
    ringSupplies: calc_ring_supply(ethereum_rpc, darwinia_rpc, metadata),
    ktonSupplies: calc_kton_supply(darwinia_rpc, metadata)
  }
end

def generate_supplies(network_name, ethereum_rpc, darwinia_rpc, metadata)
  puts "generating #{network_name} supplies data..."
  timed do
    data_dir = './data'
    FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
    File.write(
      File.join(data_dir, "#{network_name}-supplies.json"),
      calc_supply(ethereum_rpc, darwinia_rpc, metadata).to_json
    )
  end
end

require_relative "../config/config.rb"
config = get_config
darwinia_metadata = JSON.parse(File.read(config[:metadata][:darwinia]))
darwinia_rpc = config[:darwinia_rpc]
ethereum_rpc = config[:ethereum_rpc]
generate_supplies("darwinia", ethereum_rpc, darwinia_rpc, darwinia_metadata)
