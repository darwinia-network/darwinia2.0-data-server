require "scale_rb"
require_relative "supply/ring"
require_relative "supply/kton"
require_relative "./utils"

def calc_ring_supply(rpc, metadata)
  total_issuance = get_total_insurance(rpc, metadata)

  # illiquid ring
  ring_in_staking = get_staked_and_unstaking_ring(rpc, metadata)
  ring_in_deposits = get_ring_in_deposits(rpc, metadata)
  reserved_ring = get_reserved_ring(rpc, metadata)
  locked_ring = get_locked_ring(rpc, metadata)

  # illiquid ring in unmigrated accounts
  ring_in_staking_unmigrated =
    get_unmigrated_staked_and_unstaking_ring(rpc, metadata)
  ring_in_deposits_ungmirated = get_unmigrated_ring_in_deposit(rpc, metadata)

  #
  circulating_supply =
    total_issuance -
      (ring_in_staking + ring_in_deposits + reserved_ring + locked_ring) -
      (ring_in_staking_unmigrated + ring_in_deposits_ungmirated)

  {
    totalSupply: total_issuance,
    circulatingSupply: circulating_supply,
    maxSupply: 10_000_000_000,
  }
end

def calc_kton_supply(rpc, metadata)
  total_issuance = get_kton_total_insurance(rpc, metadata)

  # illiquid kton
  kton_in_staking = get_staked_and_unstaking_kton(rpc, metadata)

  # illiquid kton in unmigrated accounts
  kton_in_staking_unmigrated =
    get_unmigrated_staked_and_unstaking_kton(rpc, metadata)

  #
  circulating_supply =
    total_issuance - kton_in_staking - kton_in_staking_unmigrated

  {
    totalSupply: total_issuance,
    circulatingSupply: circulating_supply,
    maxSupply: total_issuance,
  }
end

def calc_supply(rpc, metadata)
  {
    ringSupplies: calc_ring_supply(rpc, metadata),
    ktonSupplies: calc_kton_supply(rpc, metadata),
  }
end

def generate_supplies(network_name, rpc, metadata)
  puts "generating #{network_name} supplies data..."
  timed do
    data_dir = "./data"
    FileUtils.mkdir_p(data_dir) unless File.directory?(data_dir)
    File.write(
      File.join(data_dir, "#{network_name}-supplies.json"),
      calc_supply(rpc, metadata).to_json,
    )
  end
end

# require_relative "../config/config.rb"
# config = get_config
# crab_metadata = JSON.parse(File.read(config[:metadata][:crab]))
# crab_rpc = config[:crab_rpc]

# # p calc_ring_supply(crab_rpc, crab_metadata)
# # p calc_kton_supply(crab_rpc, crab_metadata)
# # p calc_supply(crab_rpc, crab_metadata)
# generate_supplies("crab", crab_rpc, crab_metadata)
