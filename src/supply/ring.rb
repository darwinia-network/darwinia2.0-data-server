####################################################
# unmigrated accounts
####################################################
# staked and unstaking, but without the ring staked as deposit
def get_unmigrated_staked_and_unstaking_ring(rpc, metadata)
  ledgers =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      "AccountMigration",
      "Ledgers",
      nil,
      metadata,
    )
  ledgers.reduce(0) do |sum, ledger|
    sum + ledger[:storage][:staked_ring] +
      ledger[:storage][:unstaking_ring].reduce(0) do |sum, item|
        sum + item[0] # item[0] is the amount, item[1] is the block number
      end
  end / 10**18
end

def get_unmigrated_ring_in_deposit(rpc, metadata)
  deposits =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      "AccountMigration",
      "Deposits",
      nil,
      metadata,
    )
  deposits.reduce(0) do |sum, deposit|
    deposit[:storage].reduce(sum) { |sum, item| sum + item[:value] }
  end / 10**18
end

####################################################
# migrated accounts
####################################################
def get_total_insurance(rpc, metadata)
  ScaleRb::HttpClient.get_storage2(
    rpc,
    "Balances",
    "TotalIssuance",
    nil,
    metadata,
  ) / 10**18
end

def get_staked_and_unstaking_ring(rpc, metadata)
  ledgers =
    ScaleRb::HttpClient.get_storage2(
      rpc,
      "DarwiniaStaking",
      "Ledgers",
      nil,
      metadata,
    )
  ledgers.reduce(0) do |sum, ledger|
    sum + ledger[:storage][:staked_ring] +
      ledger[:storage][:unstaking_ring].reduce(0) do |sum, item|
        sum + item[0] # item[0] is the amount, item[1] is the block number
      end
  end / 10**18
end

def get_ring_in_deposits(rpc, metadata)
  deposits =
    ScaleRb::HttpClient.get_storage2(rpc, "Deposit", "Deposits", nil, metadata)
  deposits.reduce(0) do |sum, deposit|
    deposit[:storage].reduce(sum) { |sum, item| sum + item[:value] }
  end / 10**18
end

def get_reserved_ring(rpc, metadata)
  accounts =
    ScaleRb::HttpClient.get_storage2(rpc, "System", "Account", nil, metadata)
  accounts.reduce(0) do |sum, account|
    sum + account[:storage][:data][:reserved]
  end / 10**18
end

def get_locked_ring(rpc, metadata)
  # LOCKED
  locks =
    ScaleRb::HttpClient.get_storage2(rpc, "Balances", "Locks", nil, metadata)
  locks.reduce(0) do |sum, lock|
    lock[:storage].reduce(sum) { |sum, item| sum + item[:amount] }
  end / 10**18
end
