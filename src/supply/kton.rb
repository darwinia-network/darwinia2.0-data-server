####################################################
# unmigrated accounts
####################################################
def get_unmigrated_staked_and_unstaking_kton(rpc, metadata)
  ledgers =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      'AccountMigration',
      'Ledgers',
      nil,
      metadata
    )
  staking = ledgers.reduce(0) do |sum, ledger|
    sum + ledger[:storage][:staked_kton]
  end / 10**18

  unstaking = ledgers.reduce(0) do |sum, ledger|
    sum +
      ledger[:storage][:unstaking_kton].reduce(0) do |sum, item|
        sum + item[0] # item[0] is the amount, item[1] is the block number
      end
  end / 10**18

  puts "staked kton(unmigrated): #{staking}"
  puts "unstaking kton(unmigrated): #{unstaking}"
  staking + unstaking
end

####################################################
# migrated accounts
####################################################
def get_kton_total_insurance(rpc, metadata)
  ScaleRb::HttpClient
    .get_storage2(rpc, 'Assets', 'Asset', nil, metadata)
    .find do |item|
      item[:storage_key] ==
        '0x682a59d51ab9e48a8c8cc418ff9708d2d34371a193a751eea5883e9553457b2e15ffd708b25d8ed5477f01d3f9277c360204000000000000'
    end
    .dig(:storage, :supply) / 10**18
end

def get_staked_and_unstaking_kton(rpc, metadata)
  ledgers =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      'DarwiniaStaking',
      'Ledgers',
      nil,
      metadata
    )
  staking = ledgers.reduce(0) do |sum, ledger|
    sum + ledger[:storage][:staked_kton]
  end / 10**18

  unstaking = ledgers.reduce(0) do |sum, ledger|
    sum +
      ledger[:storage][:unstaking_kton].reduce(0) do |sum, item|
        sum + item[0] # item[0] is the amount, item[1] is the block number
      end
  end / 10**18

  puts "staked kton: #{staking}"
  puts "unstaking kton: #{unstaking}"
  staking + unstaking
end

# require 'json'
# require 'scale_rb'
#
# require_relative '../../config/config'
# config = get_config
# metadata = JSON.parse(File.read(config[:metadata][:darwinia]))
# rpc = config[:darwinia_rpc]
#
# total = get_staked_and_unstaking_kton(rpc, metadata)
# puts "total staking kton: #{total}"
#
# untotal = get_unmigrated_staked_and_unstaking_kton(rpc, metadata)
# puts "total staking kton(unmigrated): #{untotal}"
