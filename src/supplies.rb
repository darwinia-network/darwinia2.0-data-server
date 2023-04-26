require "scale_rb"
require "eth"
require "json"
include Eth
require_relative "supply/ring"
require_relative "supply/kton"
require_relative "./utils"

def calc_ring_supply(ethereum_rpc, darwinia_rpc, metadata)
  total_issuance = get_total_insurance(darwinia_rpc, metadata)

  darwinia_client = Eth::Client::Http.new(darwinia_rpc)
  ethereum_client = Eth::Client::Http.new(ethereum_rpc)
  
  # reserved1: Reserve on Darwinia Chain
  reserved1 = darwinia_client.eth_get_balance("0x081cbab52e2dBCd52F441c7ae9ad2a3BE42e2284")["result"].to_i(16).to_f / 10**18 # this is for RING, not CRAB

  # reserved2: Ecosystem Development Fund
  token_contract = "0x9469D013805bFfB7D3DEBe5E7839237e535ec483"
  fund_address = "0xfa4fe04f69f87859fcb31df3b9469f4e6447921c"
  data = "0x70a08231000000000000000000000000#{fund_address[2..]}"
  reserved2 =
    ethereum_client.eth_call({ to: token_contract, data: data })["result"].to_i(
      16,
    ).to_f / 10**18

  # reserved3: Treasury
  treasury_address = "0x6d6f646c64612f74727372790000000000000000"
  reserved3 =
    darwinia_client.eth_get_balance(treasury_address)["result"].to_i(16).to_f / 10**18

  {
    totalSupply: total_issuance,
    circulatingSupply: total_issuance - (reserved1 + reserved2 + reserved3).to_i,
    maxSupply: 10_000_000_000,
  }
end

def calc_kton_supply(rpc, metadata)
  total_issuance = get_kton_total_insurance(rpc, metadata)

  {
    totalSupply: total_issuance,
    circulatingSupply: total_issuance,
    maxSupply: total_issuance,
  }
end

def calc_supply(ethereum_rpc, darwinia_rpc, metadata)
  {
    ringSupplies: calc_ring_supply(ethereum_rpc, darwinia_rpc, metadata),
    ktonSupplies: calc_kton_supply(darwinia_rpc, metadata),
  }
end

def generate_supplies(network_name, ethereum_rpc, darwinia_rpc, metadata)
  puts "generating #{network_name} supplies data..."
  timed do
    data_dir = "./data"
    FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
    File.write(
      File.join(data_dir, "#{network_name}-supplies.json"),
      calc_supply(ethereum_rpc, darwinia_rpc, metadata).to_json,
    )
  end
end

# require_relative "../config/config.rb"
# config = get_config
# darwinia_metadata = JSON.parse(File.read(config[:metadata][:darwinia]))
# darwinia_rpc = config[:darwinia_rpc]
# ethereum_rpc = config[:ethereum_rpc]

# generate_supplies("darwinia", ethereum_rpc, darwinia_rpc, darwinia_metadata)
