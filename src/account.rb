require 'scale_rb'
require_relative './utils'
require_relative './storage'

def get_account_info(rpc, metadata, address)
  param = [c(address)]

  # RING
  info =
    ScaleRb::HttpClient.get_storage2(rpc, 'System', 'Account', param, metadata)
  free = info[:data][:free].to_f / 10**18
  reserved = info[:data][:reserved].to_f / 10**18

  # KTON
  kton_info =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      'Assets',
      'Account',
      [1026] + param,
      metadata
    )
  kton_free = if kton_info
                kton_info[
                    :balance
                  ].to_f / 10**18
              else
                0
              end

  # LOCKS
  locks =
    ScaleRb::HttpClient.get_storage2(rpc, 'Balances', 'Locks', param, metadata)
  locked = locks.reduce(0) { |sum, lock| lock[:amount] + sum }.to_f / 10**18

  # DEPOSITS
  deposits =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      'Deposit',
      'Deposits',
      param,
      metadata
    )
  deposits = if deposits
               deposits.map do |deposit|
                 deposit[:value] = deposit[:value].to_f / 10**18
                 deposit[:start_time] = Time.at(deposit[:start_time] / 1000)
                 deposit[:expired_time] = Time.at(deposit[:expired_time] / 1000)
                 deposit
               end
             else
               []
             end

  # STAKING LEDGER
  ledger =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      'DarwiniaStaking',
      'Ledgers',
      param,
      metadata
    )

  staked_ring =  ledger ? ledger[:staked_ring].to_f / 10**18 : 0
  unstaking_ring = if ledger
                     (ledger[:unstaking_ring].map do |item|
                        [item[0].to_f / 10**18, item[1]]
                      end.reduce(0) { |sum, item| sum + item[0] })
                   else
                     0
                   end
  staked_kton = ledger ? ledger[:staked_kton].to_f / 10**18 : 0
  unstaking_kton = if ledger
                     (ledger[:unstaking_kton].map do |item|
                        [item[0].to_f / 10**18, item[1]]
                      end.reduce(0) { |sum, item| sum + item[0] })
                   else
                     0
                   end

  {
    ring:
      free + reserved + staked_ring + unstaking_ring + deposits.reduce(0) { |sum, deposit| sum + deposit[:value] },
    kton:
      kton_free + staked_kton + unstaking_kton,
    items: {
      transferable: free - locked,
      reserved:,
      locked:,
      deposits:,
      staking: ledger
    }
  }
end

def staked_ring_in_deposits(ledger, deposits)
  if deposits.nil?
    0
  else
    # id => deposit
    all_deposits = deposits.select do |deposit|
                     deposit[:in_use] == true
                   end.map { |deposit| [deposit[:id], deposit] }.to_h
    # all_deposits = deposits.map { |deposit| [deposit[:id], deposit] }.to_h

    deposit_ids_in_ledger = ledger[:staked_deposits] # + ledger[:unstaking_deposits]
    deposit_ids_in_ledger.reduce(0) do |sum, deposit_id|
      all_deposits.key?(deposit_id) ? sum + all_deposits[deposit_id][:value] : sum
    end
  end
end

def get_all_deposits(rpc, metadata)
  # DEPOSITS
  storages = get_storage(rpc, metadata, 'deposit', 'deposits', nil, nil)
  storages.each_with_object({}) do |storage, acc|
    acc["0x#{storage[:storage_key][-40..]}"] = storage[:storage]
  end
end

def get_all_ledgers(rpc, metadata)
  # STAKING LEDGER
  storages = get_storage(rpc, metadata, 'darwinia_staking', 'ledgers', nil, nil)
  storages.each_with_object({}) do |storage, acc|
    acc["0x#{storage[:storage_key][-40..]}"] = storage[:storage]
  end
end

def get_accounts_staking_info(rpc, metadata, addresses)
  all_deposits = get_all_deposits(rpc, metadata)
  all_ledgers = get_all_ledgers(rpc, metadata)

  addresses.map(&:downcase).reduce({}) do |acc, address|
    ledger = all_ledgers[address]
    deposits = all_deposits[address]

    # staked ring in ledger + staked ring in deposits
    staked_ring =
      if ledger
        ledger[:staked_ring] +
          # ledger[:unstaking_ring].reduce(0) { |sum, item| sum + item[0] } +
          # 这个account的ledger 和 这个account的所有deposits
          staked_ring_in_deposits(ledger, deposits)
      else
        0
      end

    # staked kton in ledger
    staked_kton = ledger ? ledger[:staked_kton] : 0

    acc.merge(
      {
        address => {
          staked_ring:,
          staked_kton:
        }
      }
    )
  end
end

def get_nominee_staking_info(rpc, metadata, nominee_address)
  result = get_storage(rpc, metadata, 'darwinia_staking', 'exposures', nominee_address, nil)

  nominators = result[:nominators].map do |nominator|
    nominator[:who].to_hex
  end
  get_accounts_staking_info(rpc, metadata, nominators)
end

def get_nominee_power(rpc, metadata, address)
  staking_info = get_nominee_staking_info(rpc, metadata, address.downcase)
  total = staking_info.values.each_with_object({ staked_ring: 0, staked_kton: 0 }) do |info, acc|
    acc[:staked_ring] += info[:staked_ring]
    acc[:staked_kton] += info[:staked_kton]
  end

  ring_pool = get_storage(rpc, metadata, 'darwinia_staking', 'ring_pool', nil, nil)
  kton_pool = get_storage(rpc, metadata, 'darwinia_staking', 'kton_pool', nil, nil)

  calc_power(total[:staked_ring], total[:staked_kton], ring_pool, kton_pool)
end

def get_nominee_commissions(rpc, metadata)
  storages = get_storage(rpc, metadata, 'darwinia_staking', 'collators', nil, nil)
  storages.map do |storage|
    address = "0x#{storage[:storage_key][-40..]}"
    [address, storage[:storage] / 10_000_000]
  end.to_h
end

def get_collators(rpc, metadata)
  storages = get_storage(rpc, metadata, 'darwinia_staking', 'exposures', nil, nil)
  storages.map do |storage|
    "0x#{storage[:storage_key][-40..]}"
  end
end

# require_relative '../config/config'
# config = get_config
# crab_metadata = JSON.parse(File.read(config[:metadata][:crab]))
# crab_rpc = config[:crab_rpc]

# # collators
# puts collators(crab_rpc, crab_metadata)

# result = get_account_staking_info(
#   crab_rpc,
#   crab_metadata,
#   '0x17863f9473ce423ba00C9A3B13Be3af48B93f531'
# )
# puts JSON.pretty_generate(result)

# puts get_all_deposits(crab_rpc, crab_metadata)
# all_ledgers = get_all_ledgers(crab_rpc, crab_metadata)
# puts all_ledgers['0x82373ccc6ed8ced89293307efdcf31b73b8c49c8']
# puts get_accounts_staking_info(crab_rpc, crab_metadata,
#                                %w[0x17863f9473ce423ba00C9A3B13Be3af48B93f531 0x82373ccc6ed8ced89293307efdcf31b73b8c49c8])

# puts get_nominee_power(crab_rpc, crab_metadata, '0x0a1287977578F888bdc1c7627781AF1cc000e6ab'.downcase)
# puts get_nominee_staking_info(crab_rpc, crab_metadata, '0x0a1287977578F888bdc1c7627781AF1cc000e6ab')
