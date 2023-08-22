####################################################
# unmigrated accounts
####################################################
def get_staking_kton_unmigrated(rpc, metadata)
  ledgers = get_storage(rpc, metadata, 'account_migration', 'ledgers', nil, nil)
  ledgers.reduce(0) do |sum, ledger|
    sum + ledger[:storage][:staked_kton]
  end
end

####################################################
# migrated accounts
####################################################
def get_staking_kton(rpc, metadata)
  ledgers = get_storage(rpc, metadata, 'darwinia_staking', 'ledgers', nil, nil)
  ledgers.reduce(0) do |sum, ledger|
    sum + ledger[:storage][:staked_kton]
  end
end

def get_kton_total_insurance(rpc, metadata)
  ScaleRb::HttpClient
    .get_storage2(rpc, 'Assets', 'Asset', nil, metadata)
    .find do |item|
      item[:storage_key] ==
        '0x682a59d51ab9e48a8c8cc418ff9708d2d34371a193a751eea5883e9553457b2e15ffd708b25d8ed5477f01d3f9277c360204000000000000'
    end
    .dig(:storage, :supply) / 10**18
end

# require 'json'
# require 'scale_rb'
# require_relative '../storage'
#
# require_relative '../../config/config'
# config = get_config
# metadata = JSON.parse(File.read(config[:metadata][:darwinia]))
# rpc = config[:darwinia_rpc]
#
# puts get_staking_kton_unmigrated(rpc, metadata)
# puts get_staking_kton(rpc, metadata)
