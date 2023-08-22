def calc_staking_ring(ledgers)
  ledgers.reduce(0) do |sum, ledger|
    sum + ledger[:storage][:staked_ring]
  end
end

def calc_staking_ring_in_deposits(ledgers, all_deposits_in_use)
  staking_deposit_ids = ledgers.reduce([]) do |acc, ledger|
    acc + ledger[:storage][:staked_deposits]
  end

  staking_deposit_ids.reduce(0) do |sum, deposit_id|
    all_deposits_in_use.key?(deposit_id) ? sum + all_deposits_in_use[deposit_id][:value] : sum
  end
end

def handle_deposits_storages(storages)
  storages.each_with_object({}) do |storage, acc|
    # {
    #   :storage_key=>"0x1fb3231abc71c5a12c573bc57e9d12d174a614db8021c6bd0a028aafdf29dd080091926c50a7544a24728ea18e183845ce11f8d5737b5f0783c072fa15e38f64e338f844d4135bd0c311e1ea95513f25",
    #   :storage=>[
    #     {:id=>0, :value=>100000000000000000000000, :start_time=>1605600300003, :expired_time=>1667808300003, :in_use=>true}
    #   ]
    # }
    address = "0x#{storage[:storage_key][-40..]}"
    items = storage[:storage]
    items.each do |item|
      acc[address] = item if item[:in_use]
    end
  end
end

####################################################
# unmigrated accounts
####################################################
def get_all_staking_ring_unmigrated(rpc, metadata)
  ledgers = get_storage(rpc, metadata, 'account_migration', 'ledgers', nil, nil)
  calc_staking_ring(ledgers)

  # all_deposits_in_use = handle_deposits_storages(
  #   get_storage(rpc, metadata, 'account_migration', 'deposits', nil, nil)
  # )
  # staked_ring_in_deposits = calc_staking_ring_in_deposits(ledgers, all_deposits_in_use)

  # {
  #   staking_ring:, staked_ring_in_deposits:
  # }
end

####################################################
# migrated accounts
####################################################
def get_all_staking_ring(rpc, metadata)
  ledgers = get_storage(rpc, metadata, 'darwinia_staking', 'ledgers', nil, nil)
  calc_staking_ring(ledgers)

  # all_deposits_in_use = handle_deposits_storages(
  #   get_storage(rpc, metadata, 'deposit', 'deposits', nil, nil)
  # )
  #
  # staked_ring_in_deposits = calc_staking_ring_in_deposits(ledgers, all_deposits_in_use)
  #
  # {
  #   staking_ring:, staked_ring_in_deposits:
  # }
end

##########################################
def get_total_insurance(rpc, metadata)
  ScaleRb::HttpClient.get_storage2(
    rpc,
    'Balances',
    'TotalIssuance',
    nil,
    metadata
  ) / 10**18
end

def get_reserved_ring(rpc, metadata)
  accounts =
    ScaleRb::HttpClient.get_storage2(rpc, 'System', 'Account', nil, metadata)
  accounts.reduce(0) do |sum, account|
    sum + account[:storage][:data][:reserved]
  end / 10**18
end

def get_locked_ring(rpc, metadata)
  # LOCKED
  locks =
    ScaleRb::HttpClient.get_storage2(rpc, 'Balances', 'Locks', nil, metadata)
  locks.reduce(0) do |sum, lock|
    lock[:storage].reduce(sum) { |sum, item| sum + item[:amount] }
  end / 10**18
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
# puts get_all_staking_ring_unmigrated(rpc, metadata)
# puts get_all_staking_ring(rpc, metadata)
