require "scale_rb"

# ## Storage
# -------------------------------
#
# system.account: FrameSystemAccountInfo
# {
#   nonce: 13
#   consumers: 4
#   providers: 1
#   sufficients: 1
#   data: {
#     free: 14,512,288,096,158,638,790,418
#     reserved: 200,135,400,000,000,000,000 // name
#     miscFrozen: 13,767,198,376,240,536,966,688 // gov + vesting
#     feeFrozen: 13,767,198,376,240,536,966,688
#   }
# }
#
# darwiniaStaking.ledgers: Option<DarwiniaStakingLedger>
# {
#   stakedRing: 999,000,000,000,000,000,000
#   stakedKton: 0
#   stakedDeposits: []
#   unstakingRing: [
#     [
#       1,000,000,000,000,000,000
#       154,375 // blocknumber
#     ]
#   ]
#   unstakingKton: []
#   unstakingDeposits: []
# }
#
# balances.locks: Vec<PalletBalancesBalanceLock>
# [
#   {
#     id: phrelect
#     amount: 13,767,198,376,240,536,966,688
#     reasons: All
#   }
# ]
#
# ## https://polkadot.js.org/apps
# -------------------------------
#
# total
# 14,712.4234 CRAB  = (transferrable + locked)(account_info.data.free) + reserved(account_info.data.reserved) 
#
# transferrable
# 745.0897 CRAB = metamask balance
#
# locked
# 13,767.1983 CRAB 
#   = balances.locks
#   = max(account_info.data.miscFrozen, account_info.data.feeFrozen)
#
# reserved
# 200.1354 CRAB = account_info.data.reserved
#
# ## https://staking.darwinia.network
# -------------------------------
#
# Reserved in staking(bonded) = ledger.stakedRing
# unbonding = ledger.unstakingRing

def get_data
  # prepare darwinia metadata
  metadata_content = File.read(File.join(__dir__, 'config', 'crab2.json'))
  metadata = JSON.parse(metadata_content)

  url = 'https://crab-rpc.darwinia.network'

  # TOTAL SUPPLY
  total_issuance = ScaleRb::HttpClient.get_storage2(url, 'Balances', 'TotalIssuance', nil, metadata)
  total_supply = (total_issuance / 10**18).floor

  # CRAB IN STAKING
  crab_in_staking = ScaleRb::HttpClient.get_storage2(url, 'DarwiniaStaking', 'RingPool', nil, metadata)
  crab_in_staking = (crab_in_staking / 10**18).floor

  # CKTON IN STAKING
  ckton_in_staking = ScaleRb::HttpClient.get_storage2(url, 'DarwiniaStaking', 'KtonPool', nil, metadata)
  ckton_in_staking = (ckton_in_staking / 10**18).floor

  # CRAB IN DEPOSIT
  deposits = ScaleRb::HttpClient.get_storage2(url, 'Deposit', 'Deposits', nil, metadata)
  crab_in_deposit = deposits.reduce(0) do |sum, deposit|
    deposit[:storage].reduce(sum) do |sum, item|
      sum + item[:value]
    end
  end
  crab_in_deposit = (crab_in_deposit / 10**18).floor

  # RESERVED
  accounts = ScaleRb::HttpClient.get_storage2(url, 'System', 'Account', nil, metadata)
  reserved = accounts.reduce(0) do |sum, account|
    sum + account[:storage][:data][:reserved]
  end
  reserved = (reserved / 10**18).floor

  # LOCKED
  locks = ScaleRb::HttpClient.get_storage2(url, 'Balances', 'Locks', nil, metadata)
  locked = locks.reduce(0) do |sum, lock|
    lock[:storage].reduce(sum) do |sum, item|
      sum + item[:amount]
    end
  end
  locked = (locked / 10**18).floor

  # VESTING LOCKED which is part of locked
  # height = ScaleRb::HttpClient.get_storage2(url, 'System', 'Number', nil, metadata)
  # vesting_list = ScaleRb::HttpClient.get_storage2(url, 'Vesting', 'Vesting', nil, metadata)
  # vesting_locked = vesting_list.reduce(0) do |sum, vesting|
  #   vesting[:storage].reduce(sum) do |sum, item|
  #     sum + (item[:locked] - item[:per_block] * (height - item[:starting_block]))
  #   end
  # end
  # vesting_locked = (vesting_locked / 10**18).floor

  # TOTAL ILLIQUID
  # in staking + in deposit + locked
  _total_illiquid = crab_in_staking + crab_in_deposit + reserved + locked

  # CIRCULATING SUPPLY
  circulating_supply = total_supply - _total_illiquid
  

  {
    total_supply: total_supply,
    #
    crab_in_staking: crab_in_staking,
    ckton_in_staking: ckton_in_staking,
    crab_in_deposit: crab_in_deposit,
    reserved: reserved,
    locked: locked,
    # 
    circulating_supply: circulating_supply
  }
end
