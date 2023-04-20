require "scale_rb"
require_relative "./utils"

def get_account_info(rpc, metadata, address)
  param = [c(address)]

  # RING
  info =
    ScaleRb::HttpClient.get_storage2(rpc, "System", "Account", param, metadata)
  free = info[:data][:free].to_f / 10**18
  reserved = info[:data][:reserved].to_f / 10**18

  # KTON
  kton_free =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      "Assets",
      "Account",
      [1026] + param,
      metadata,
    )[
      :balance
    ].to_f / 10**18

  # LOCKS
  locks =
    ScaleRb::HttpClient.get_storage2(rpc, "Balances", "Locks", param, metadata)
  locked = locks.reduce(0) { |sum, lock| lock[:amount] + sum }.to_f / 10**18

  # DEPOSITS
  deposits =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      "Deposit",
      "Deposits",
      param,
      metadata,
    )
  deposits =
    deposits.map do |deposit|
      deposit[:value] = deposit[:value].to_f / 10**18
      deposit[:start_time] = Time.at(deposit[:start_time] / 1000)
      deposit[:expired_time] = Time.at(deposit[:expired_time] / 1000)
      deposit
    end

  # STAKING LEDGER
  ledger =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      "DarwiniaStaking",
      "Ledgers",
      param,
      metadata,
    )
  ledger[:staked_ring] = ledger[:staked_ring].to_f / 10**18
  ledger[:unstaking_ring] = ledger[:unstaking_ring].map do |item|
    [item[0].to_f / 10**18, item[1]]
  end
  ledger[:staked_kton] = ledger[:staked_kton].to_f / 10**18
  ledger[:unstaking_kton] = ledger[:unstaking_kton].map do |item|
    [item[0].to_f / 10**18, item[1]]
  end

  {
    ring:
      free + reserved + ledger[:staked_ring] +
        ledger[:unstaking_ring].reduce(0) { |sum, item| sum + item[0] } +
        deposits.reduce(0) { |sum, deposit| sum + deposit[:value] },
    kton:
      kton_free + ledger[:staked_kton] +
        ledger[:unstaking_kton].reduce(0) { |sum, item| sum + item[0] },
    items: {
      transferable: free - locked,
      reserved: reserved,
      locked: locked,
      deposits: deposits,
      staking: ledger,
    },
  }
end

# require_relative "../config/config.rb"
# config = get_config
# crab_metadata = JSON.parse(File.read(config[:metadata][:crab]))
# crab_rpc = config[:crab_rpc]

# p get_account_info(
#     crab_rpc,
#     crab_metadata,
#     "0x20FF2599f29876D5a5345a5cD6592BEd749CECEa",
#   )
